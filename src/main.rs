use anyhow::Result;
use clap::Parser;
use futures::TryStreamExt;
use opendal::services::Git;
use opendal::Operator;
use std::future::Future;
use std::path::PathBuf;
use std::pin::Pin;

/// Git repository inspector using OpenDAL Git service
#[derive(Parser, Debug)]
#[command(name = "gix-demo")]
#[command(about = "Demonstrate OpenDAL Git service with LFS support")]
struct Args {
    /// Repository URL (https://...)
    repository: String,

    /// Git ref to checkout (branch, tag, or commit SHA, defaults to HEAD)
    #[arg(short, long)]
    ref_name: Option<String>,

    /// Path within repository to list
    #[arg(short, long, default_value = "/")]
    path: String,

    /// Username for authentication
    #[arg(short, long)]
    username: Option<String>,

    /// Password or token for authentication
    #[arg(short = 'P', long)]
    password: Option<String>,

    /// Download files to this directory
    #[arg(short, long)]
    output_dir: Option<PathBuf>,

    /// Maximum files to list
    #[arg(long, default_value = "1000")]
    max_files: usize,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    println!("OpenDAL Git Service Demo");
    println!("========================");
    println!();
    println!("Repository: {}", args.repository);
    println!("Reference: {}", args.ref_name.as_deref().unwrap_or("HEAD"));
    println!("Path: {}", args.path);
    println!();

    // Build the Git service
    let mut builder = Git::default().repository(&args.repository);

    if let Some(ref username) = args.username {
        builder = builder.username(username);
    }

    if let Some(ref password) = args.password {
        builder = builder.password(password);
    }

    if let Some(ref ref_name) = args.ref_name {
        builder = builder.reference(ref_name);
    }

    // LFS is enabled by default
    builder = builder.resolve_lfs(true);

    // Create operator
    let op: Operator = Operator::new(builder)?.finish();

    println!("Listing files...");
    println!();

    // Recursive download
    let mut count = 0;
    let mut total_size = 0u64;

    fn process_directory<'a>(
        op: &'a Operator,
        path: &'a str,
        output_dir: &'a Option<std::path::PathBuf>,
        count: &'a mut usize,
        total_size: &'a mut u64,
        max_files: usize,
    ) -> Pin<Box<dyn Future<Output = Result<bool>> + 'a>> {
        Box::pin(async move {
            let mut lister = op.lister(path).await?;

            while let Some(entry) = lister.try_next().await? {
                if *count >= max_files {
                    return Ok(true); // Hit limit
                }

                let metadata = entry.metadata();
                let entry_path = entry.path();
                let size = metadata.content_length();

                // Construct full path (entry.path() is already full path from root)
                let full_path = entry_path.to_string();

                if metadata.is_file() {
                    *total_size += size;
                    *count += 1;
                    println!("  {} ({} bytes)", full_path, size);

                    // Download if output directory is specified
                    if let Some(ref output_dir) = output_dir {
                        let output_path = output_dir.join(full_path.trim_start_matches('/'));

                        // Create parent directories
                        if let Some(parent) = output_path.parent() {
                            std::fs::create_dir_all(parent)?;
                        }

                        // Stream file to disk in chunks (handles large files efficiently)
                        let mut file = std::fs::File::create(&output_path)?;

                        // Read and write in chunks to avoid loading entire file in memory
                        const CHUNK_SIZE: u64 = 8 * 1024 * 1024; // 8MB chunks
                        const PROGRESS_INTERVAL: u64 = 100 * 1024 * 1024; // Report every 100MB
                        let mut offset = 0u64;
                        let mut last_progress = 0u64;

                        // Show initial progress for large files (>100MB)
                        let show_progress = size > PROGRESS_INTERVAL;
                        if show_progress {
                            println!("    Downloading: 0 MB / {} MB (0%)", size / (1024 * 1024));
                        }

                        loop {
                            let end = if size > 0 {
                                // For known sizes, don't read past the end
                                (offset + CHUNK_SIZE).min(size)
                            } else {
                                offset + CHUNK_SIZE
                            };

                            let chunk = op.read_with(&full_path).range(offset..end).await?;

                            if chunk.is_empty() {
                                break;
                            }

                            std::io::Write::write_all(&mut file, &chunk.to_bytes())?;
                            offset += chunk.len() as u64;

                            // Print progress every 100MB for large files
                            if show_progress && (offset - last_progress) >= PROGRESS_INTERVAL {
                                let progress_pct = if size > 0 { (offset * 100) / size } else { 0 };
                                println!(
                                    "    Downloading: {} MB / {} MB ({}%)",
                                    offset / (1024 * 1024),
                                    size / (1024 * 1024),
                                    progress_pct
                                );
                                last_progress = offset;
                            }

                            // Stop if we've read everything
                            if size > 0 && offset >= size {
                                break;
                            }

                            if chunk.len() < CHUNK_SIZE as usize {
                                break;
                            }
                        }

                        // Show final progress for large files
                        if show_progress {
                            println!("    Downloaded: {} MB (100%)", size / (1024 * 1024));
                        }
                    }
                } else if metadata.is_dir() {
                    println!("  {}", full_path);

                    // Recursively process subdirectory (use the full path with trailing slash)
                    if process_directory(op, &full_path, output_dir, count, total_size, max_files)
                        .await?
                    {
                        return Ok(true); // Hit limit in subdirectory
                    }
                }
            }

            Ok(false)
        })
    }

    let hit_limit = process_directory(
        &op,
        &args.path,
        &args.output_dir,
        &mut count,
        &mut total_size,
        args.max_files,
    )
    .await?;

    if hit_limit {
        println!();
        println!("... (truncated, {} file limit reached)", args.max_files);
    }

    println!();
    println!("Summary:");
    println!("--------");
    println!("Files listed: {}", count);
    println!(
        "Total size: {} bytes ({:.2} MB)",
        total_size,
        total_size as f64 / 1_048_576.0
    );

    if let Some(ref output_dir) = args.output_dir {
        println!("Files downloaded to: {}", output_dir.display());
    }

    Ok(())
}
