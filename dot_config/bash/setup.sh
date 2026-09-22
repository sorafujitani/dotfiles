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
  # MySQL slow query analysis and diagnostics
  percona-toolkit
)
apt_command=(apt-get)
if (( EUID != 0 )); then
  command -v sudo >/dev/null || { printf '%s\n' 'Install sudo or run as root.' >&2; exit 1; }
  apt_command=(sudo apt-get)
fi
"${apt_command[@]}" update
"${apt_command[@]}" install -y "${packages[@]}"

for tool in rg fdfind pt-query-digest; do
  command -v "$tool" >/dev/null || { printf 'Missing command after installation: %s\n' "$tool" >&2; exit 1; }
done

# Keep Vim plugins and their compatible binary separate from apt's Bash fzf.
# Versioned directories leave existing user plugins untouched.
vim_plugins=$HOME/.vim/dotfiles
mkdir -p "$vim_plugins"
install_vim_plugin() (
  local name=$1 repository=$2 revision=$3
  local destination=$vim_plugins/$name
  [[ ! -d $destination ]] || exit 0
  local plugin_tmp
  plugin_tmp=$(mktemp -d "$vim_plugins/.install.XXXXXX")
  trap 'rm -rf -- "$plugin_tmp"' EXIT
  git init -q "$plugin_tmp"
  git -C "$plugin_tmp" remote add origin "$repository"
  git -C "$plugin_tmp" fetch --depth 1 origin "$revision"
  git -C "$plugin_tmp" checkout -q --detach FETCH_HEAD
  mv "$plugin_tmp" "$destination"
)
install_vim_plugin fzf-v0.65.2 https://github.com/junegunn/fzf.git v0.65.2
install_vim_plugin fzf.vim-8a006812 https://github.com/junegunn/fzf.vim.git 8a0068127ac9ee23d71dab2944ce995726bef462
bash "$vim_plugins/fzf-v0.65.2/install" --bin
"$vim_plugins/fzf-v0.65.2/bin/fzf" --version

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

# Install pprotein and its log analyzers; leave existing commands untouched.
(
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) printf 'Unsupported pprotein architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
  esac
  pprotein_tmp=$(mktemp -d)
  trap 'rm -rf -- "$pprotein_tmp"' EXIT
  mkdir -p "$HOME/.local/bin"
  for tool in pprotein alp slp; do
    if command -v "$tool" >/dev/null 2>&1 &&
      { [[ $tool != pprotein ]] || command -v pprotein-agent >/dev/null 2>&1; }; then
      continue
    fi
    case "$tool" in
      pprotein) release="kaz/pprotein/releases/download/v1.2.4/pprotein_1.2.4_linux_${arch}.tar.gz"; binaries=(pprotein pprotein-agent) ;;
      alp) release="tkuchiki/alp/releases/download/v1.0.21/alp_linux_${arch}.tar.gz"; binaries=(alp) ;;
      slp) release="tkuchiki/slp/releases/download/v0.2.1/slp_linux_${arch}.tar.gz"; binaries=(slp) ;;
    esac
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
      "https://github.com/$release" --output "$pprotein_tmp/$tool.tar.gz"
    tar -xzf "$pprotein_tmp/$tool.tar.gz" -C "$pprotein_tmp" "${binaries[@]}"
    for binary in "${binaries[@]}"; do
      command -v "$binary" >/dev/null 2>&1 || install -m 755 "$pprotein_tmp/$binary" "$HOME/.local/bin/$binary"
    done
  done
)

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
