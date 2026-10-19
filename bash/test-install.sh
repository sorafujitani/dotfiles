#!/usr/bin/env bash
# Offline integration test: real config installers, mocked downloads and apt.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export TEST_SOURCE_DIR="$script_dir/.."
export HOME="$test_dir/home"
export XDG_CONFIG_HOME="$HOME/custom config"
export CODEX_HOME="$HOME/custom codex"
export TMPDIR="$test_dir/tmp"
mkdir -p "$HOME" "$TMPDIR" "$test_dir/bin" "$CODEX_HOME"
export PATH="$test_dir/bin:$PATH"

printf '#!/bin/sh\necho "${TEST_OS:-Linux}"\n' > "$test_dir/bin/uname"
printf '#!/bin/sh\nexit 99\n' > "$test_dir/bin/apt-get"
printf '#!/bin/sh\n[ "${1-}" != -H ] || shift\nexec "$@"\n' > "$test_dir/bin/sudo"
cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -eu
url=$4
output=$6
base=https://raw.githubusercontent.com/sorafujitani/dotfiles/main
[[ $url == "$base/"* ]] || exit 1
file=${url#"$base/"}
[[ $file != "${FAIL_DOWNLOAD:-}" ]] || exit 22
case "$file" in
  bash/interactive.bash) printf 'export TEST_BASH_LOADED=1\n' > "$output" ;;
  bash/setup.sh)
    if [[ ${REAL_SETUP:-0} == 1 ]]; then
      cp "$TEST_SOURCE_DIR/bash/setup.sh" "$output"
    else
      printf 'printf "setup ran\\n" > "$HOME/setup-ran"\nexit "${SETUP_STATUS:-0}"\n' > "$output"
    fi
    ;;
  bash/setup-root-vim.sh) printf '[ -s "$1" ] || exit 1\nprintf "root setup ran\\n" > "$HOME/root-vim-setup-ran"\n' > "$output" ;;
  vim/sudo.vim) cp "$TEST_SOURCE_DIR/vim/sudo.vim" "$output" ;;
  vim/.vimrc) printf 'set number\n' > "$output" ;;
  codex/install.sh) cp "$TEST_SOURCE_DIR/codex/install.sh" "$output" ;;
  codex/config.toml) cp "$TEST_SOURCE_DIR/codex/config.toml" "$output" ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "$test_dir/bin/"*
config_dir="$XDG_CONFIG_HOME/bash"
printf 'old vim config\n' > "$HOME/.vimrc"
printf 'old codex config\n' > "$CODEX_HOME/config.toml"
printf 'keep auth\n' > "$CODEX_HOME/auth.json"
printf 'keep hooks\n' > "$CODEX_HOME/hooks.json"

# Unsupported platforms and late download failures must not change any configs.
if TEST_OS=Darwin bash "$script_dir/install.sh"; then exit 1; fi
[[ ! -e $config_dir ]]
if FAIL_DOWNLOAD=codex/config.toml bash "$script_dir/install.sh"; then exit 1; fi
[[ ! -e $config_dir ]]
[[ $(< "$HOME/.vimrc") == 'old vim config' ]]
[[ $(< "$CODEX_HOME/config.toml") == 'old codex config' ]]

bash "$script_dir/install.sh"
[[ $(< "$config_dir/interactive.bash") == 'export TEST_BASH_LOADED=1' ]]
[[ $(< "$HOME/.vimrc") == 'set number' ]]
cmp "$TEST_SOURCE_DIR/codex/config.toml" "$CODEX_HOME/config.toml"
[[ $(< "$CODEX_HOME/auth.json") == 'keep auth' ]]
[[ $(< "$CODEX_HOME/hooks.json") == 'keep hooks' ]]
[[ -f $HOME/setup-ran ]]
[[ -f $HOME/root-vim-setup-ran ]]
backups=("$HOME"/.vimrc.backup.*)
[[ ${#backups[@]} == 1 && $(< "${backups[0]}") == 'old vim config' ]]
backups=("$CODEX_HOME"/config.toml.dotfiles-backup.*)
[[ ${#backups[@]} == 1 && $(< "${backups[0]}") == 'old codex config' ]]

printf 'custom config\n' > "$config_dir/interactive.bash"
rm "$HOME/setup-ran"
if FAIL_DOWNLOAD=bash/setup.sh bash "$script_dir/install.sh"; then exit 1; fi
[[ $(< "$config_dir/interactive.bash") == 'custom config' ]]
[[ ! -e $HOME/setup-ran ]]

bash "$script_dir/install.sh"
backups=("$config_dir"/interactive.bash.backup.*)
[[ ${#backups[@]} == 1 && $(< "${backups[0]}") == 'custom config' ]]
backups=("$HOME"/.vimrc.backup.*)
[[ ${#backups[@]} == 1 ]]
backups=("$CODEX_HOME"/config.toml.dotfiles-backup.*)
[[ ${#backups[@]} == 1 ]]
[[ -f $HOME/setup-ran ]]

# A symlink must be backed up, not followed when replacing the Vim config.
printf 'managed vim config\n' > "$HOME/managed-vimrc"
rm "$HOME/.vimrc"
ln -s "$HOME/managed-vimrc" "$HOME/.vimrc"
bash "$script_dir/install.sh"
[[ ! -L $HOME/.vimrc && $(< "$HOME/.vimrc") == 'set number' ]]
[[ $(< "$HOME/managed-vimrc") == 'managed vim config' ]]
backups=("$HOME"/.vimrc.backup.*)
[[ ${#backups[@]} == 2 ]]
[[ -L ${backups[0]} || -L ${backups[1]} ]]

if SETUP_STATUS=42 bash "$script_dir/install.sh"; then
  exit 1
else
  [[ $? == 42 ]]
fi

# Run the actual setup: a tool failure must not prevent Bash activation.
printf '# keep bashrc\n' > "$HOME/.bashrc"
printf '# keep profile\n' > "$HOME/.profile"
for _attempt in 1 2; do
  if REAL_SETUP=1 bash "$script_dir/install.sh" > "$test_dir/failure.log" 2>&1; then
    exit 1
  else
    [[ $? == 99 ]]
  fi
  grep -q 'apt packages failed' "$test_dir/failure.log"
  [[ $(grep -c '# dotfiles portable bash' "$HOME/.bashrc") == 1 ]]
  [[ $(grep -c '# dotfiles interactive bash login' "$HOME/.profile") == 1 ]]
  grep -q '# keep bashrc' "$HOME/.bashrc"
  grep -q '# keep profile' "$HOME/.profile"
  [[ $(< "$HOME/.vimrc") == 'set number' ]]
  cmp "$TEST_SOURCE_DIR/codex/config.toml" "$CODEX_HOME/config.toml"
done
bash --noprofile --norc -ic '. "$HOME/.profile"; [[ $TEST_BASH_LOADED == 1 ]]'
backups=("$HOME"/.bashrc.before-dotfiles-bash.*)
[[ ${#backups[@]} == 1 && $(< "${backups[0]}") == '# keep bashrc' ]]
[[ -z $(ls -A "$TMPDIR") ]]
printf '%s\n' 'install.sh: all checks passed'
