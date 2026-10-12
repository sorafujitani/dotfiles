#!/bin/sh
# Link repository files into HOME; never replace whole tool directories.
set -eu

usage() {
    printf 'Usage: sh install.sh [--dry-run]\n'
}
dry_run=false
case "${1:-}" in
    '') ;;
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

repo=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
home=$(CDPATH= cd -P "${HOME:?HOME is required}" && pwd)
config_home=${XDG_CONFIG_HOME:-$home/.config}
case "$config_home" in
    /*) ;;
    *) printf 'XDG_CONFIG_HOME must be an absolute path.\n' >&2; exit 1 ;;
esac
backup_suffix=.dotfiles-backup.$(date +%Y%m%d%H%M%S).$$
umask 077

# Refuse symlinked parents rather than writing into another checkout.
check_directory() (
    directory=$1
    while [ "$directory" != / ]; do
        if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
            printf '[FAIL] Not a regular directory: %s\n' "$directory" >&2
            exit 1
        fi
        directory=${directory%/*}
        [ -n "$directory" ] || directory=/
    done
)

link_file() (
    source=$1
    destination=$2
    target=$source
    # These links retain the home-relative targets from the original configs.
    if [ -L "$source" ]; then
        target=$(readlink "$source")
    fi
    parent=${destination%/*}
    [ -n "$parent" ] || parent=/
    check_directory "$parent"
    if [ -d "$parent" ]; then
        destination=$(CDPATH= cd -P "$parent" && pwd)/${destination##*/}
    fi
    [ "$source" != "$destination" ] || exit 0
    case "$repo/" in
        "$destination/"*)
            printf '[FAIL] Destination contains the repository: %s\n' "$destination" >&2
            exit 1
            ;;
    esac
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$target" ]; then
        exit 0
    fi
    if [ "$phase" = check ]; then
        if [ -e "$destination" ] || [ -L "$destination" ]; then
            printf '[BACKUP] %s\n' "$destination"
        fi
        printf '[LINK] %s -> %s\n' "$destination" "$target"
        exit 0
    fi

    [ -d "$parent" ] || mkdir -p "$parent"
    backup=''
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        backup=$destination$backup_suffix
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            printf '[FAIL] Backup already exists: %s\n' "$backup" >&2
            exit 1
        fi
        mv "$destination" "$backup"
        printf '[SAVED] %s\n' "$backup"
    fi
    if ! ln -s "$target" "$destination"; then
        if [ -n "$backup" ]; then
            mv "$backup" "$destination"
        fi
        exit 1
    fi
)

link_tree() (
    source_dir=$1
    destination_dir=$2
    # Keep tool/skill directories already linked to another manager intact.
    if [ -L "$destination_dir" ]; then
        if [ "$phase" = check ]; then
            printf '[SKIP] Existing directory link: %s\n' "$destination_dir"
        fi
        exit 0
    fi
    for source in "$source_dir"/* "$source_dir"/.[!.]* "$source_dir"/..?*; do
        [ -e "$source" ] || [ -L "$source" ] || continue
        name=${source##*/}
        [ "$name" != .git ] || continue
        if [ -d "$source" ] && [ ! -L "$source" ]; then
            link_tree "$source" "$destination_dir/$name"
        else
            link_file "$source" "$destination_dir/$name"
        fi
    done
)

install_links() {
    for tool in bash claude codex emacs ghostty herdr home-manager hunk nix nvim omp opencode pi scripts wezterm zeno zshctl; do
        [ -d "$repo/$tool" ] || continue
        case "$tool" in
            claude|codex|omp|pi) destination=$home/.$tool ;;
            scripts) destination=$home/.local/bin ;;
            *) destination=$config_home/$tool ;;
        esac
        link_tree "$repo/$tool" "$destination"
    done
    for name in .zprofile .zshenv .zshrc; do
        [ ! -f "$repo/zsh/$name" ] || link_file "$repo/zsh/$name" "$home/$name"
    done
    [ ! -f "$repo/vim/.vimrc" ] || link_file "$repo/vim/.vimrc" "$home/.vimrc"
    [ ! -f "$repo/AGENTS.md" ] || link_file "$repo/AGENTS.md" "$home/AGENTS.md"
}

# Validate every destination before backing up or replacing any file.
phase=check
install_links
if [ "$dry_run" = false ]; then
    phase=apply
    install_links
    printf 'Links installed. Existing files were kept in .dotfiles-backup.* files.\n'
fi
