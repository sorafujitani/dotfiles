#!/usr/bin/env bash
# Downloads official releases into a temporary HOME; never runs Linux binaries.
set -euo pipefail
setup=$(cd "$(dirname "$0")" && pwd)/setup.sh
test_tmp=$(mktemp -d)
trap 'rm -rf -- "$test_tmp"' EXIT
# Exercise the actual installer block without apt or shell configuration changes.
awk '/^# Install pprotein / { copy=1 } copy { print } copy && /^\)$/ { exit }' \
  "$setup" > "$test_tmp/install.sh"
[[ -s $test_tmp/install.sh ]]
for machine in x86_64 aarch64; do
  (
    export HOME="$test_tmp/$machine"
    export PATH="$HOME/.local/bin:/usr/bin:/bin"
    uname() { printf '%s\n' "$machine"; }
    source "$test_tmp/install.sh"
    for tool in pprotein pprotein-agent alp slp; do
      [[ -x $HOME/.local/bin/$tool ]]
      file "$HOME/.local/bin/$tool" | grep -q ELF
    done
    # Re-running must preserve installed binaries without another download.
    curl() { printf '%s\n' 'Unexpected download' >&2; return 1; }
    source "$test_tmp/install.sh"
  )
done
if (uname() { printf '%s\n' riscv64; }; source "$test_tmp/install.sh"); then
  printf '%s\n' 'Unsupported architecture was accepted' >&2
  exit 1
fi
printf '%s\n' 'PASS: both architectures, repeat install, unsupported architecture'
