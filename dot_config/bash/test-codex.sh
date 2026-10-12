#!/usr/bin/env bash
# Offline test: exercise the installer block with fake release archives.
set -euo pipefail
setup=$(cd "$(dirname "$0")" && pwd)/setup.sh
test_tmp=$(mktemp -d)
trap 'rm -rf -- "$test_tmp"' EXIT
awk '/^# Install Codex / { copy=1 } copy { print } copy && /^\)$/ { exit }' \
  "$setup" > "$test_tmp/install.sh"
[[ -s $test_tmp/install.sh ]]

for machine in x86_64 amd64 aarch64 arm64; do
  (
    export HOME="$test_tmp/$machine"
    export TMPDIR="$test_tmp/tmp-$machine"
    export PATH="$HOME/.local/bin:/usr/bin:/bin"
    mkdir -p "$TMPDIR"
    uname() { printf '%s\n' "$machine"; }
    curl() {
      local url output
      while (( $# )); do
        case "$1" in
          https://*) url=$1 ;;
          --output) shift; output=$1 ;;
        esac
        shift
      done
      case "$machine" in
        x86_64|amd64) expected=x86_64 ;;
        aarch64|arm64) expected=aarch64 ;;
      esac
      [[ $url == "https://github.com/openai/codex/releases/download/rust-v0.162.1/codex-$expected-unknown-linux-musl.tar.gz" ]]
      local archive_dir="$test_tmp/archive-$machine"
      mkdir -p "$archive_dir"
      printf '#!/bin/sh\necho "codex-cli test"\n' > "$archive_dir/codex-$expected-unknown-linux-musl"
      tar -czf "$output" -C "$archive_dir" "codex-$expected-unknown-linux-musl"
    }
    source "$test_tmp/install.sh"
    [[ -x $HOME/.local/bin/codex ]]
    [[ $(codex --version) == 'codex-cli test' ]]
    [[ -z $(ls -A "$TMPDIR") ]]

    # Installed commands must be preserved without downloading again.
    printf '#!/bin/sh\necho "existing codex"\n' > "$HOME/.local/bin/codex"
    curl() { printf '%s\n' 'Unexpected download' >&2; return 1; }
    source "$test_tmp/install.sh"
    [[ $(codex --version) == 'existing codex' ]]
  )
done

# Reject unsupported hardware and propagate download failure without installing.
for failure in architecture download; do
  (
    export HOME="$test_tmp/$failure"
    export TMPDIR="$test_tmp/tmp-$failure"
    export PATH="$HOME/.local/bin:/usr/bin:/bin"
    mkdir -p "$TMPDIR"
    if [[ $failure == architecture ]]; then
      uname() { printf '%s\n' riscv64; }
    else
      uname() { printf '%s\n' x86_64; }
    fi
    curl() { return 22; }
    # Use a separate shell so errexit remains active for the sourced block.
    export -f uname curl
    if bash -e "$test_tmp/install.sh"; then exit 1; fi
    [[ ! -e $HOME/.local/bin/codex ]]
    [[ -z $(ls -A "$TMPDIR") ]]
  )
done
printf '%s\n' 'PASS: Codex architectures, existing install, unsupported architecture, download failure'
