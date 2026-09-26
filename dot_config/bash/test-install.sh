#!/usr/bin/env bash
# Offline test: mock downloads and setup, never install packages.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export HOME="$test_dir/home"
export XDG_CONFIG_HOME="$HOME/custom config"
export TMPDIR="$test_dir/tmp"
mkdir -p "$HOME" "$TMPDIR" "$test_dir/bin"
export PATH="$test_dir/bin:$PATH"

printf '#!/bin/sh\necho "${TEST_OS:-Linux}"\n' > "$test_dir/bin/uname"
printf '#!/bin/sh\nexit 99\n' > "$test_dir/bin/apt-get"
cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -eu
url=$4
output=$6
case "$url" in
  */interactive.bash) printf 'new config\n' > "$output" ;;
  */setup.sh)
    [[ ${FAIL_DOWNLOAD:-0} != 1 ]] || exit 22
    printf 'printf "setup ran\\n" > "$HOME/setup-ran"\nexit "${SETUP_STATUS:-0}"\n' > "$output"
    ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "$test_dir/bin/"*
config_dir="$XDG_CONFIG_HOME/bash"

# Unsupported platforms must not write configuration.
if TEST_OS=Darwin bash "$script_dir/install.sh"; then exit 1; fi
[[ ! -e $config_dir ]]

bash "$script_dir/install.sh"
[[ $(< "$config_dir/interactive.bash") == 'new config' ]]
[[ -f $HOME/setup-ran ]]

printf 'custom config\n' > "$config_dir/interactive.bash"
rm "$HOME/setup-ran"
if FAIL_DOWNLOAD=1 bash "$script_dir/install.sh"; then exit 1; fi
[[ $(< "$config_dir/interactive.bash") == 'custom config' ]]
[[ ! -e $HOME/setup-ran ]]

bash "$script_dir/install.sh"
backups=("$config_dir"/interactive.bash.backup.*)
[[ ${#backups[@]} == 1 ]]
[[ $(< "${backups[0]}") == 'custom config' ]]
[[ -f $HOME/setup-ran ]]

if SETUP_STATUS=42 bash "$script_dir/install.sh"; then
  exit 1
else
  [[ $? == 42 ]]
fi
[[ -z $(ls -A "$TMPDIR") ]]
printf '%s\n' 'install.sh: all checks passed'
