#!/bin/sh
# Install portable Codex defaults and personal skills.
set -eu

usage() {
    printf 'Usage: sh codex/install.sh [--download] [--dry-run] [--skills-only | --without-skills]\n'
}
dry_run=false
download=false
skills_only=false
with_skills=true
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=true ;;
        --download) download=true ;;
        --skills-only) skills_only=true ;;
        --without-skills) with_skills=false ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

if [ "$skills_only" = true ] && [ "$with_skills" = false ]; then
    usage >&2
    exit 2
fi

codex_home=${CODEX_HOME:-${HOME:?HOME is required}/.codex}
case "$codex_home" in
    /*) ;;
    *) printf 'CODEX_HOME must be an absolute path.\n' >&2; exit 1 ;;
esac
destination=$codex_home/config.toml
[ "$skills_only" = true ] || [ ! -d "$destination" ] || {
    printf 'Config path is a directory: %s\n' "$destination" >&2
    exit 1
}

umask 077
download_dir=''
staged=''
skills_stage=''
cleanup() {
    [ -z "$staged" ] || rm -f "$staged"
    [ -z "$download_dir" ] || rm -rf "$download_dir"
    [ -z "$skills_stage" ] || rm -rf "$skills_stage"
}
trap cleanup EXIT HUP INT TERM

install_skills() {
    skills_home=$(CDPATH= cd -P "${HOME:?HOME is required}" && pwd)
    skills_repo=$skills_home/ghq/github.com/sorafujitani/skills
    skills_destination=$skills_home/.agents/skills
    skills_url=https://github.com/sorafujitani/skills.git
    if [ "$dry_run" = true ]; then
        printf '[SKILLS] Clone/update %s -> %s; link skills into %s (existing skills preserved)\n' \
            "$skills_url" "$skills_repo" "$skills_destination"
        return
    fi
    command -v git >/dev/null 2>&1 || {
        printf 'git is required to install skills. Use --without-skills for config only.\n' >&2
        exit 1
    }
    # Do not write through managed directory links into another installation.
    for directory in "$skills_repo" "$skills_destination"; do
        while [ "$directory" != "$skills_home" ]; do
            if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
                printf 'Not a regular directory: %s\n' "$directory" >&2
                exit 1
            fi
            directory=${directory%/*}
            [ -n "$directory" ] || directory=/
        done
    done
    if [ -e "$skills_repo" ]; then
        [ -d "$skills_repo/.git" ] &&
            [ "$(git -C "$skills_repo" config --get remote.origin.url)" = "$skills_url" ] &&
            [ "$(git -C "$skills_repo" symbolic-ref --short HEAD)" = main ] &&
            [ -z "$(git -C "$skills_repo" status --porcelain)" ] || {
                printf 'Skills checkout must be a clean main branch of %s: %s\n' "$skills_url" "$skills_repo" >&2
                exit 1
            }
        git -C "$skills_repo" fetch origin main
        # Reject unpublished commits as well as divergence; never reset local work.
        git -C "$skills_repo" merge-base --is-ancestor HEAD FETCH_HEAD || {
            printf 'Skills checkout has local commits; update it manually: %s\n' "$skills_repo" >&2
            exit 1
        }
        git -C "$skills_repo" merge --ff-only FETCH_HEAD
    else
        mkdir -p "${skills_repo%/*}"
        skills_stage=$(mktemp -d "${skills_repo%/*}/.skills.XXXXXX")
        git clone --depth 1 --branch main "$skills_url" "$skills_stage"
        mv "$skills_stage" "$skills_repo"
        skills_stage=''
    fi
    mkdir -p "$skills_destination"
    for skill in "$skills_repo"/*; do
        [ -d "$skill" ] && [ ! -L "$skill" ] && [ -f "$skill/SKILL.md" ] || continue
        name=${skill##*/}
        link=$skills_destination/$name
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then
            continue
        fi
        # Preserve user/external skills, including legacy Codex installations.
        if [ -e "$link" ] || [ -L "$link" ] ||
            [ -e "$codex_home/skills/$name" ] || [ -L "$codex_home/skills/$name" ]; then
            printf '[SKIP] Existing skill: %s\n' "$name"
            continue
        fi
        ln -s "$skill" "$link"
        printf '[LINK] %s -> %s\n' "$link" "$skill"
    done
    printf '[OK] Skills ready. Restart Codex to load them.\n'
}

if [ "$skills_only" = true ]; then
    install_skills
    exit 0
fi
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
if [ "$with_skills" = true ]; then
    install_skills
fi
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
