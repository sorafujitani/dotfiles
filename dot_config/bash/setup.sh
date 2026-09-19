#!/usr/bin/env bash
# Run on Linux after downloading this directory or applying it with chezmoi.
# Install Ubuntu/Debian packages with the bootstrap script in README.md first.
set -euo pipefail

if [[ $(uname -s) != Linux ]]; then
  printf '%s\n' 'This setup is for Linux. No shell settings were changed.' >&2
  exit 1
fi

if (( BASH_VERSINFO[0] < 4 )); then
  printf '%s\n' 'Use Bash 4+ to enable history autosuggestions.' >&2
  exit 1
fi
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/bash
data_dir=${XDG_DATA_HOME:-$HOME/.local/share}
[[ -r $config_dir/interactive.bash ]] || { printf '%s\n' "Missing $config_dir/interactive.bash" >&2; exit 1; }

if [[ ! -r $data_dir/blesh/ble.sh ]]; then
  for dependency in curl tar xz; do
    command -v "$dependency" >/dev/null || { printf 'Missing command: %s\n' "$dependency" >&2; exit 1; }
  done
  setup_tmp=$(mktemp -d)
  trap 'rm -rf -- "$setup_tmp"' EXIT
  curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
    https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
    --output "$setup_tmp/ble.tar.xz"
  tar -xJf "$setup_tmp/ble.tar.xz" -C "$setup_tmp"
  bash "$setup_tmp/ble-nightly/ble.sh" --install "$data_dir"
fi

# Append only our loader; keep the existing distribution/user configuration.
append_loader() {
  local target=$1 marker=$2 content=$3
  if [[ -f $target ]] && grep -Fq -- "$marker" "$target"; then
    return
  fi
  if [[ -e $target ]]; then
    cp -p -- "$target" "$target.before-dotfiles-bash.$(date +%Y%m%d%H%M%S).$$"
  fi
  printf '\n# %s\n%s\n' "$marker" "$content" >> "$target"
}

append_loader "$HOME/.bashrc" 'dotfiles portable bash' \
  '[[ ! -r ${XDG_CONFIG_HOME:-$HOME/.config}/bash/interactive.bash ]] || source "${XDG_CONFIG_HOME:-$HOME/.config}/bash/interactive.bash"'

# Bash uses the first existing login profile. Keep its original setup intact.
profile_file=$HOME/.bash_profile
for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
  if [[ -f $candidate ]]; then
    profile_file=$candidate
    break
  fi
done
append_loader "$profile_file" 'dotfiles interactive bash login' \
  'if [ -n "${BASH_VERSION-}" ]; then
  case $- in
    *i*) [ "${_DOTFILES_BASH_LOADED-}" = "$$" ] || . "$HOME/.bashrc" ;;
  esac
fi'

printf '%s\n' 'Installed. Run: exec bash -l'
if ! command -v fzf >/dev/null 2>&1; then
  printf '%s\n' 'Optional: install fzf for the Ctrl-R history picker.'
fi
if [[ ! -r /usr/share/bash-completion/bash_completion && ! -r /etc/bash_completion ]]; then
  printf '%s\n' 'Install bash-completion for command-specific option completion.'
fi
