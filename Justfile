# ----------------------------
# Gix Demo Justfile
# ----------------------------

# Command menu
default:
	@bash "{{ SCRIPT_DIR }}/just-menu.sh"

# ---------
# Settings
# ---------
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set export := true
set dotenv-load := true

SCRIPT_DIR := "scripts"

# -----------------------------
# Build & Developer Utilities
# -----------------------------

# Build the project
build *args:
    cargo build {{ args }}
    @echo ">>> Built gix-demo"
alias b := build

# Build the project in release mode
build-release *args:
    cargo build --release {{ args }}
    @echo ">>> Built gix-demo in release mode"
    @echo ">>> Binary: target/release/gix-demo"
alias br := build-release

# Format the codebase prior to PR submission
format:
    cargo fmt --all
alias f := format
alias fmt := format

# Static analysis to ensure code will compile without compiling
check:
    cargo check
alias c := check

# Run clippy for linting
clippy:
    cargo clippy --all-targets --all-features -- -D warnings
alias cl := clippy

# Run MR pre-flight to prepare for contributions
mr:
    { just check && just test-all && just fmt && echo "You are ready to submit an MR!"; } \
      || { echo "A stage of the MR preparation failed, please fix this prior to submission." >&2; exit 1; }

# ---------------------------------
# Runtime & Local Entry Points
# ---------------------------------

# Run gix-demo with arguments (use: just run fetch-ref <url>)
run *args:
    cargo run -- {{ args }}
alias r := run

# Run gix-demo in release mode
run-release *args:
    cargo run --release -- {{ args }}
alias rr := run-release

# ----------------------
# Test Suites / Commands
# ----------------------

# Run unit tests
test-unit:
    cargo test --lib
alias tu := test-unit

# Run integration tests (requires network access, takes 1-2 minutes)
test-integration:
    cargo test --features integration-tests
alias ti := test-integration

# Run all tests (unit + integration)
test-all: test-unit test-integration
alias t := test-all

# Run all tests without integration tests
test-fast:
    cargo test
alias tf := test-fast

# Generate code coverage (includes integration tests)
# Requires: cargo install cargo-tarpaulin
# Note: Runs integration tests against real repositories (takes 4-5 minutes)
coverage:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ">>> Generating coverage for gix-demo with integration tests..."
    echo ">>> This will take 4-5 minutes (network requests to GitLab, GitHub, HuggingFace)"
    cargo tarpaulin --features integration-tests --out Stdout --timeout 300
    echo ""
    echo ">>> Expected: ~72% coverage (374/520 lines)"
    echo ">>> For HTML report: cargo tarpaulin --features integration-tests --out Html --output-dir coverage-report --timeout 300"
alias cov := coverage

# Generate HTML coverage report
coverage-html:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ">>> Generating HTML coverage report..."
    cargo tarpaulin --features integration-tests --out Html --output-dir coverage-report --timeout 300
    echo ">>> Coverage report generated at coverage-report/index.html"
alias covh := coverage-html

# --------------------
# Documentation
# --------------------

# Generate and open documentation
doc:
    cargo doc --no-deps --open
alias d := doc

# Generate documentation without opening
doc-build:
    cargo doc --no-deps
alias db := doc-build

# --------------------
# Clean Commands
# --------------------

# Clean build artifacts
clean:
    cargo clean
    @echo ">>> Cleaned build artifacts"

# Clean and rebuild
rebuild: clean build
    @echo ">>> Cleaned and rebuilt project"
