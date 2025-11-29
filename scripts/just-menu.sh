#!/usr/bin/env bash
set -euo pipefail

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  TITLE=$'\033[1;36m'
  SECTION=$'\033[1;34m'
  NAME=$'\033[1;33m'
  ALIAS=$'\033[1;32m'
  RESET=$'\033[0m'
else
  TITLE=''
  SECTION=''
  NAME=''
  ALIAS=''
  RESET=''
fi

print_header() {
  printf '\n%sGix Demo Task Catalog%s\n' "$TITLE" "$RESET"
  printf '======================\n'
}

print_section() {
  local title="$1"
  shift
  printf '\n%s[%s]%s\n' "$SECTION" "$title" "$RESET"
  while (($#)); do
    IFS='|' read -r recipe description <<<"$1"
    printf '  %s%-26s%s %s\n' "$NAME" "$recipe" "$RESET" "$description"
    shift
  done
}

print_aliases() {
  printf '\n%sAliases%s\n' "$SECTION" "$RESET"
  while (($#)); do
    IFS='|' read -r alias target <<<"$1"
    printf '  %s%-10s%s -> %s\n' "$ALIAS" "$alias" "$RESET" "$target"
    shift
  done
}

print_header
print_section "Build/QA" \
  'build [args]|Build gix-demo' \
  'build-release [args]|Build gix-demo in release mode' \
  'format|Format the codebase prior to PR submission' \
  'check|Static analysis to ensure code will compile without compiling' \
  'clippy|Run clippy for linting' \
  'mr|Run MR pre-flight (check, test, fmt)'
print_section "Runtime" \
  'run [args]|Run gix-demo with arguments (e.g., fetch-ref <url>)' \
  'run-release [args]|Run gix-demo in release mode'
print_section "Testing" \
  'test-unit|Run unit tests' \
  'test-integration|Run integration tests (requires network, takes 1-2 minutes)' \
  'test-all|Run all tests (unit + integration)' \
  'test-fast|Run all tests without integration tests' \
  'coverage|Generate code coverage (includes integration tests)' \
  'coverage-html|Generate HTML coverage report'
print_section "Documentation" \
  'doc|Generate and open documentation' \
  'doc-build|Generate documentation without opening'
print_section "Utilities" \
  'clean|Clean build artifacts' \
  'rebuild|Clean and rebuild project'
print_aliases \
  'b|build' \
  'br|build-release' \
  'f/fmt|format' \
  'c|check' \
  'cl|clippy' \
  'r|run' \
  'rr|run-release' \
  'tu|test-unit' \
  'ti|test-integration' \
  't|test-all' \
  'tf|test-fast' \
  'cov|coverage' \
  'covh|coverage-html' \
  'd|doc' \
  'db|doc-build'
printf '\nTip: run `just <task>` to execute a recipe or `just --list` for the raw listing.\n\n'
