#!/bin/sh
# Install portable Codex defaults from local files or GitHub.
set -eu

usage() {
    printf 'Usage: sh codex/install.sh [--download] [--dry-run]\n'
}
dry_run=false
download=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=true ;;
        --download) download=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

codex_home=${CODEX_HOME:-${HOME:?HOME is required}/.codex}
case "$codex_home" in
    /*) ;;
    *) printf 'CODEX_HOME must be an absolute path.\n' >&2; exit 1 ;;
esac
destination=$codex_home/config.toml
[ ! -d "$destination" ] || {
    printf 'Config path is a directory: %s\n' "$destination" >&2
    exit 1
}

umask 077
download_dir=''
staged=''
cleanup() {
    [ -z "$staged" ] || rm -f "$staged"
    [ -z "$download_dir" ] || rm -rf "$download_dir"
}
trap cleanup EXIT HUP INT TERM
if [ "$download" = true ]; then
    command -v curl >/dev/null 2>&1 || {
        printf 'curl is required to download the config.\n' >&2
        exit 1
    }
    download_dir=$(mktemp -d "${TMPDIR:-/tmp}/codex-config.XXXXXX")
    source_config=$download_dir/config.toml
    curl -fL --retry 2 \
        https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/config.toml \
        -o "$source_config"
else
    source_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
    source_config=$source_dir/config.toml
fi
[ -s "$source_config" ] || {
    printf 'Missing or empty config: %s\n' "$source_config" >&2
    exit 1
}
if [ -f "$destination" ] && cmp -s "$source_config" "$destination"; then
    printf '[OK] Config already matches: %s\n' "$destination"
    exit 0
fi
if [ "$dry_run" = true ]; then
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        printf '[BACKUP] %s\n' "$destination"
    fi
    printf '[COPY] %s -> %s\n' "$source_config" "$destination"
    exit 0
fi

mkdir -p "$codex_home"
staged=$(mktemp "$codex_home/.config.toml.XXXXXX")
cat "$source_config" > "$staged"
backup=''
if [ -e "$destination" ] || [ -L "$destination" ]; then
    backup=$destination.dotfiles-backup.$(date +%Y%m%d%H%M%S).$$
    [ ! -e "$backup" ] && [ ! -L "$backup" ] || {
        printf 'Backup already exists: %s\n' "$backup" >&2
        exit 1
    }
    mv "$destination" "$backup"
    printf '[SAVED] %s\n' "$backup"
fi
if ! mv "$staged" "$destination"; then
    [ -z "$backup" ] || mv "$backup" "$destination"
    exit 1
fi
printf '[OK] Installed: %s\nRestart Codex to load the config.\n' "$destination"
