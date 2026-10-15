#!/bin/sh
# Exercise config replacement and preservation in disposable directories, offline.
set -eu
source_repo=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
repo=$temporary/repo\ with\ spaces
mkdir -p "$repo/codex"
cp "$source_repo/codex/install.sh" "$source_repo/codex/config.toml" "$repo/codex/"
installer=$repo/codex/install.sh
export CODEX_HOME="$temporary/codex home"

sh "$installer" --without-skills --dry-run > "$temporary/new-dry-run"
[ ! -e "$CODEX_HOME" ]
mkdir -p "$CODEX_HOME"
printf 'old config\n' > "$CODEX_HOME/config.toml"
printf 'keep auth\n' > "$CODEX_HOME/auth.json"
printf 'keep hooks\n' > "$CODEX_HOME/hooks.json"
sh "$installer" --without-skills --dry-run > "$temporary/existing-dry-run"
[ "$(cat "$CODEX_HOME/config.toml")" = 'old config' ]
[ -z "$(find "$CODEX_HOME" -name '*.dotfiles-backup.*' -print)" ]

sh "$installer" --without-skills > "$temporary/install"
cmp "$repo/codex/config.toml" "$CODEX_HOME/config.toml"
[ ! -L "$CODEX_HOME/config.toml" ]
[ "$(cat "$CODEX_HOME/auth.json")" = 'keep auth' ]
[ "$(cat "$CODEX_HOME/hooks.json")" = 'keep hooks' ]
set -- "$CODEX_HOME/config.toml.dotfiles-backup."*
[ "$#" -eq 1 ] && [ "$(cat "$1")" = 'old config' ]
backups=$(find "$CODEX_HOME" -name '*.dotfiles-backup.*' -print)
sh "$installer" --without-skills > "$temporary/repeat"
[ "$backups" = "$(find "$CODEX_HOME" -name '*.dotfiles-backup.*' -print)" ]

# Back up a linked config without modifying its original source.
export CODEX_HOME="$temporary/linked-config"
mkdir -p "$CODEX_HOME"
printf 'managed elsewhere\n' > "$temporary/original.toml"
ln -s "$temporary/original.toml" "$CODEX_HOME/config.toml"
sh "$installer" --without-skills > "$temporary/link-install"
cmp "$repo/codex/config.toml" "$CODEX_HOME/config.toml"
[ "$(cat "$temporary/original.toml")" = 'managed elsewhere' ]
set -- "$CODEX_HOME/config.toml.dotfiles-backup."*
[ "$#" -eq 1 ] && [ "$(readlink "$1")" = "$temporary/original.toml" ]

# Restore the old config if the final move fails.
export CODEX_HOME="$temporary/failure"
mkdir -p "$CODEX_HOME" "$temporary/bin"
printf 'restore me\n' > "$CODEX_HOME/config.toml"
cat > "$temporary/bin/mv" <<'MOCK'
#!/bin/sh
case "$1" in
    */.config.toml.*) exit 1 ;;
    *) exec /bin/mv "$@" ;;
esac
MOCK
chmod +x "$temporary/bin/mv"
if PATH="$temporary/bin:$PATH" sh "$installer" --without-skills > /dev/null 2>&1; then exit 1; fi
[ "$(cat "$CODEX_HOME/config.toml")" = 'restore me' ]
[ -z "$(find "$CODEX_HOME" -name '.config.toml.*' -print)" ]

export CODEX_HOME="$temporary/directory-config"
mkdir -p "$CODEX_HOME/config.toml"
if sh "$installer" --without-skills > /dev/null 2>&1; then exit 1; fi
[ -d "$CODEX_HOME/config.toml" ]
if CODEX_HOME=relative sh "$installer" --without-skills > /dev/null 2>&1; then exit 1; fi
if sh "$installer" --without-skills --unknown > /dev/null 2>&1; then exit 1; fi
if sh "$installer" --without-skills --dry-run extra > /dev/null 2>&1; then exit 1; fi

# A downloaded installer must work without a dotfiles checkout beside it.
cp "$installer" "$temporary/setup-codex.sh"
download_installer=$temporary/setup-codex.sh
mkdir -p "$temporary/download-bin" "$temporary/download-tmp"
export TMPDIR="$temporary/download-tmp"
export DOTFILES_TEST_CONFIG="$repo/codex/config.toml"
cat > "$temporary/download-bin/curl" <<'MOCK'
#!/bin/sh
set -eu
[ "$1" = -fL ] && [ "$2" = --retry ] && [ "$3" = 2 ]
[ "$4" = https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/config.toml ]
[ "$5" = -o ]
case "${DOTFILES_TEST_DOWNLOAD_RESULT:-success}" in
    failure) printf 'partial download\n' > "$6"; exit 22 ;;
    empty) : > "$6" ;;
    success) cat "$DOTFILES_TEST_CONFIG" > "$6" ;;
esac
MOCK
chmod +x "$temporary/download-bin/curl"
export CODEX_HOME="$temporary/downloaded-config"
PATH="$temporary/download-bin:$PATH" sh "$download_installer" --without-skills --download --dry-run > "$temporary/download-dry-run"
[ ! -e "$CODEX_HOME" ]
[ -z "$(find "$TMPDIR" -mindepth 1 -print)" ]
PATH="$temporary/download-bin:$PATH" sh "$download_installer" --without-skills --download > "$temporary/download-install"
cmp "$DOTFILES_TEST_CONFIG" "$CODEX_HOME/config.toml"
[ -z "$(find "$TMPDIR" -mindepth 1 -print)" ]
PATH="$temporary/download-bin:$PATH" sh "$download_installer" --without-skills --download > "$temporary/download-repeat"
[ -z "$(find "$CODEX_HOME" -name '*.dotfiles-backup.*' -print)" ]

# A failed or empty download must preserve the existing config and credentials.
printf 'keep remote config\n' > "$CODEX_HOME/config.toml"
printf 'keep remote auth\n' > "$CODEX_HOME/auth.json"
for result in failure empty; do
    if DOTFILES_TEST_DOWNLOAD_RESULT="$result" PATH="$temporary/download-bin:$PATH" \
        sh "$download_installer" --without-skills --download > /dev/null 2>&1; then exit 1; fi
    [ "$(cat "$CODEX_HOME/config.toml")" = 'keep remote config' ]
    [ "$(cat "$CODEX_HOME/auth.json")" = 'keep remote auth' ]
    [ -z "$(find "$CODEX_HOME" -name '*.dotfiles-backup.*' -print)" ]
    [ -z "$(find "$TMPDIR" -mindepth 1 -print)" ]
done
printf 'PASS: local/download install, dry-run, backups, auth/hooks preservation, repeat, symlink, rollback, failed/empty download, cleanup, invalid paths/options\n'
