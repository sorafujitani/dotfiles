#!/usr/bin/env bash
# Install Vim, Bash and portable Codex defaults, then set up tools and skills.
set -euo pipefail

if [[ $(uname -s) != Linux ]]; then
  printf '%s\n' 'Ubuntu / Debian で実行してください。' >&2
  exit 1
fi
command -v apt-get >/dev/null || { printf '%s\n' 'Ubuntu / Debian が必要です。' >&2; exit 1; }
command -v curl >/dev/null || { printf '%s\n' 'curl を先にインストールしてください。' >&2; exit 1; }

stage=download
trap 'status=$?; printf "[ERROR] %s failed (exit %s). Fix the error above and rerun this installer.\n" "$stage" "$status" >&2; exit "$status"' ERR
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
base_url=https://raw.githubusercontent.com/sorafujitani/dotfiles/main
printf '[START] Installing for %s (HOME=%s)\n' "$(id -un)" "$HOME"
printf '%s\n' '[DOWNLOAD] Vim, Bash and Codex configuration'
# Finish all configuration downloads before replacing any existing files.
for file in bash/interactive.bash bash/setup.sh bash/setup-root-vim.sh vim/.vimrc vim/sudo.vim codex/install.sh codex/config.toml; do
  mkdir -p "$download_dir/$(dirname "$file")"
  curl -fL --retry 2 "$base_url/$file" -o "$download_dir/$file"
  [[ -s $download_dir/$file ]] || { printf 'Empty download: %s\n' "$file" >&2; exit 1; }
done

install_config() {
  local source=$1 destination=$2
  [[ ! -d $destination ]] || { printf 'Config path is a directory: %s\n' "$destination" >&2; return 1; }
  if [[ -f $destination ]] && cmp -s "$source" "$destination"; then
    printf '[OK] Already matches: %s\n' "$destination"
    return
  fi
  if [[ -e $destination || -L $destination ]]; then
    local backup=$destination.backup.$(date +%Y%m%d%H%M%S).$$
    cp -Pp -- "$destination" "$backup"
    printf '[SAVED] %s\n' "$backup"
  fi
  # Replace symlinks rather than overwriting files in another managed checkout.
  mv -f -- "$source" "$destination"
  printf '[OK] Installed: %s\n' "$destination"
}

stage='Vim and Bash configuration'
mkdir -p "$config_dir"
for file in interactive.bash setup.sh; do
  install_config "$download_dir/bash/$file" "$config_dir/$file"
done
install_config "$download_dir/vim/.vimrc" "$HOME/.vimrc"

stage='sudo Vim configuration'
printf '%s\n' '[VIM] Enabling the same configuration under sudo'
if (( EUID == 0 )); then
  sh "$download_dir/bash/setup-root-vim.sh" "$download_dir/vim/sudo.vim"
else
  command -v sudo >/dev/null || { printf '%s\n' 'Install sudo to configure root Vim.' >&2; exit 1; }
  sudo -H sh "$download_dir/bash/setup-root-vim.sh" "$download_dir/vim/sudo.vim"
fi

stage='Codex configuration'
printf '%s\n' '[CODEX] Installing config.toml (approval=never, sandbox=danger-full-access)'
# Apply defaults before optional tool/skill downloads can fail.
sh "$download_dir/codex/install.sh" --without-skills

stage='Bash activation and tools'
bash "$config_dir/setup.sh"
printf '%s\n' '[OK] Vim, Bash, Codex configuration and tools installed.'
