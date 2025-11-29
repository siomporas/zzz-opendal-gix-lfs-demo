# Git Service Demo for OpenDAL

Demo CLI for the OpenDAL Git service with transparent LFS support.

## Getting Started

```bash
# Clone with submodules
git clone --recursive https://github.com/siomporas/zzz-opendal-gix-lfs-demo.git
cd zzz-opendal-gix-lfs-demo

# Or if already cloned, initialize submodules
git submodule update --init --recursive

# Build (using just)
just build

# Or build with cargo directly
cargo build --release
```

## Usage

Using `just` recipes:
```bash
# Build
just build

# Run against a repository
just run https://github.com/apache/opendal

# Run tests
just test-all
```

Or use the binary directly:
```bash
# List files in a repository
./target/release/gix-demo https://github.com/apache/opendal

# Specify a branch, tag, or commit SHA
./target/release/gix-demo https://github.com/apache/opendal --ref-name main

# List a specific path
./target/release/gix-demo https://github.com/apache/opendal --path /core

# With authentication for private repos
./target/release/gix-demo https://github.com/user/private-repo \
  --username youruser \
  --password your-token

# Download files to a directory
./target/release/gix-demo https://huggingface.co/openai-community/gpt2 \
  --output-dir ./output \
  --max-files 100
```

## License

Apache License 2.0
