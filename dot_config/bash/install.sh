#!/usr/bin/env bash
# Download the Bash configuration, then run the existing setup.
set -euo pipefail

if [[ $(uname -s) != Linux ]]; then
  printf '%s\n' 'Ubuntu / Debian で実行してください。' >&2
  exit 1
fi
command -v apt-get >/dev/null || { printf '%s\n' 'Ubuntu / Debian が必要です。' >&2; exit 1; }
command -v curl >/dev/null || { printf '%s\n' 'curl を先にインストールしてください。' >&2; exit 1; }

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
base_url=https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_config/bash
for file in interactive.bash setup.sh; do
  curl -fL --retry 2 "$base_url/$file" -o "$download_dir/$file"
done

mkdir -p "$config_dir"
for file in interactive.bash setup.sh; do
  if [[ -e "$config_dir/$file" ]]; then
    cp -p "$config_dir/$file" "$config_dir/$file.backup.$(date +%Y%m%d%H%M%S).$$"
  fi
  cp "$download_dir/$file" "$config_dir/$file"
done
bash "$config_dir/setup.sh"
