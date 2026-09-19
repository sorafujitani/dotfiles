#!/usr/bin/env bash
# Run on Linux after downloading this directory or applying it with chezmoi.
# Installs Ubuntu/Debian packages and configures the current user's Bash.
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

command -v apt-get >/dev/null || { printf '%s\n' 'This setup requires Ubuntu/Debian (apt-get).' >&2; exit 1; }
packages=(
  bash-completion fzf curl ca-certificates xz-utils
  git vim ripgrep fd-find bat tree less jq
  tmux htop lsof rsync unzip
  # Process, network and disk diagnostics
  strace tcpdump dnsutils iproute2 procps psmisc ncdu
  # File inspection, archives and shell script checks
  file zip shellcheck
)
apt_command=(apt-get)
if (( EUID != 0 )); then
  command -v sudo >/dev/null || { printf '%s\n' 'Install sudo or run as root.' >&2; exit 1; }
  apt_command=(sudo apt-get)
fi
"${apt_command[@]}" update
"${apt_command[@]}" install -y "${packages[@]}"

for tool in rg fdfind; do
  command -v "$tool" >/dev/null || { printf 'Missing command after installation: %s\n' "$tool" >&2; exit 1; }
done

# Install Herdr for the current user with the official checksum-verifying installer.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
if ! command -v herdr >/dev/null 2>&1; then
  (
    herdr_tmp=$(mktemp -d)
    trap 'rm -rf -- "$herdr_tmp"' EXIT
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
      https://herdr.dev/install.sh --output "$herdr_tmp/install.sh"
    HERDR_INSTALL_DIR="$HOME/.local/bin" sh "$herdr_tmp/install.sh"
  )
fi
herdr --version

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
