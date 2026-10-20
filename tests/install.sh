#!/bin/sh
# All writes are confined to a disposable HOME and repository fixture.
set -eu
source_repo=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
temporary=$(CDPATH= cd -P "$temporary" && pwd)
repo=$temporary/repo\ with\ spaces
mkdir -p "$repo/nvim" "$repo/claude/skills" "$repo/scripts" "$repo/zsh" "$repo/vim" "$repo/pi/agent"
cp "$source_repo/install.sh" "$repo/install.sh"
printf 'nvim original\n' > "$repo/nvim/init.lua"
printf '{}\n' > "$repo/claude/settings.json"
printf '{}\n' > "$repo/pi/agent/settings.json"
printf 'shell config\n' > "$repo/zsh/.zshrc"
printf 'vim config\n' > "$repo/vim/.vimrc"
printf 'agent guidance\n' > "$repo/AGENTS.md"
printf 'do not install\n' > "$repo/README.md"
printf '#!/bin/sh\nexit 0\n' > "$repo/scripts/example"
chmod +x "$repo/scripts/example"
ln -s ../../.agents/skills/shared "$repo/claude/skills/shared"
unset XDG_CONFIG_HOME
export HOME="$temporary/home"
mkdir -p "$HOME/.config/nvim" "$HOME/.claude"
printf 'old nvim\n' > "$HOME/.config/nvim/init.lua"
printf 'old settings\n' > "$HOME/.claude/settings.json"
printf 'keep credentials\n' > "$HOME/.claude/auth.json"
ln -s missing-old-target "$HOME/.zshrc"

sh "$repo/install.sh" --dry-run > "$temporary/dry-run"
[ ! -L "$HOME/.config/nvim/init.lua" ]
[ "$(cat "$HOME/.claude/settings.json")" = 'old settings' ]
[ ! -e "$HOME/AGENTS.md" ]
[ -z "$(find "$HOME" -name '*.dotfiles-backup.*' -print)" ]

sh "$repo/install.sh" > "$temporary/install"
[ "$(readlink "$HOME/.config/nvim/init.lua")" = "$repo/nvim/init.lua" ]
[ "$(readlink "$HOME/.claude/settings.json")" = "$repo/claude/settings.json" ]
[ "$(readlink "$HOME/.claude/skills/shared")" = ../../.agents/skills/shared ]
[ "$(readlink "$HOME/.pi/agent/settings.json")" = "$repo/pi/agent/settings.json" ]
[ "$(readlink "$HOME/.zshrc")" = "$repo/zsh/.zshrc" ]
[ "$(readlink "$HOME/.vimrc")" = "$repo/vim/.vimrc" ]
[ "$(readlink "$HOME/AGENTS.md")" = "$repo/AGENTS.md" ]
[ -x "$HOME/.local/bin/example" ]
[ ! -e "$HOME/README.md" ]
[ "$(cat "$HOME/.claude/auth.json")" = 'keep credentials' ]
set -- "$HOME/.config/nvim/init.lua.dotfiles-backup."*
[ "$#" -eq 1 ] && [ "$(cat "$1")" = 'old nvim' ]
set -- "$HOME/.claude/settings.json.dotfiles-backup."*
[ "$#" -eq 1 ] && [ "$(cat "$1")" = 'old settings' ]
set -- "$HOME/.zshrc.dotfiles-backup."*
[ "$#" -eq 1 ] && [ "$(readlink "$1")" = missing-old-target ]
backups=$(find "$HOME" -name '*.dotfiles-backup.*' -print | sort)
sh "$repo/install.sh" > "$temporary/repeat"
[ "$backups" = "$(find "$HOME" -name '*.dotfiles-backup.*' -print | sort)" ]
printf 'edited through config\n' > "$HOME/.config/nvim/init.lua"
[ "$(cat "$repo/nvim/init.lua")" = 'edited through config' ]
printf 'edited in repo\n' > "$repo/nvim/init.lua"
[ "$(cat "$HOME/.config/nvim/init.lua")" = 'edited in repo' ]
mkdir -p "$repo/nvim/lua"
printf 'new file\n' > "$repo/nvim/lua/new.lua"
sh "$repo/install.sh" > "$temporary/add-file"
[ -L "$HOME/.config/nvim/lua/new.lua" ]

# Moving the repository only requires rerunning the installer.
old_repo=$repo
repo=$temporary/relocated\ repo\ with\ spaces
mv "$old_repo" "$repo"
sh "$repo/install.sh" --dry-run > "$temporary/relocate-dry-run"
[ "$(readlink "$HOME/.config/nvim/init.lua")" = "$old_repo/nvim/init.lua" ]
sh "$repo/install.sh" > "$temporary/relocate"
[ "$(readlink "$HOME/.config/nvim/init.lua")" = "$repo/nvim/init.lua" ]
[ "$(readlink "$HOME/.config/nvim/lua/new.lua")" = "$repo/nvim/lua/new.lua" ]
[ "$(readlink "$HOME/.zshrc")" = "$repo/zsh/.zshrc" ]
[ "$(readlink "$HOME/.claude/skills/shared")" = ../../.agents/skills/shared ]
[ "$(cat "$HOME/.config/nvim/init.lua")" = 'edited in repo' ]
[ "$(cat "$HOME/.claude/auth.json")" = 'keep credentials' ]
backups=$(find "$HOME" -name '*.dotfiles-backup.*' -print | sort)
sh "$repo/install.sh" > "$temporary/relocate-repeat"
[ "$backups" = "$(find "$HOME" -name '*.dotfiles-backup.*' -print | sort)" ]

export HOME="$temporary/xdg-home" XDG_CONFIG_HOME="$temporary/custom config"
mkdir -p "$HOME"
sh "$repo/install.sh" > "$temporary/xdg"
[ -L "$XDG_CONFIG_HOME/nvim/init.lua" ]
[ ! -e "$HOME/.config" ]
if XDG_CONFIG_HOME=relative sh "$repo/install.sh" > /dev/null 2>&1; then exit 1; fi
unset XDG_CONFIG_HOME

export HOME="$temporary/blocked-home"
mkdir -p "$HOME/.config" "$HOME/.claude" "$temporary/other-checkout"
printf 'untouched\n' > "$HOME/.claude/settings.json"
ln -s "$temporary/other-checkout" "$HOME/.config/nvim"
sh "$repo/install.sh" > "$temporary/skip-directory"
[ "$(readlink "$HOME/.config/nvim")" = "$temporary/other-checkout" ]
[ ! -e "$temporary/other-checkout/init.lua" ]
[ -L "$HOME/.claude/settings.json" ]
grep -q '\[SKIP\]' "$temporary/skip-directory"

# A linked common parent is still rejected before any files are changed.
export HOME="$temporary/parent-link-home"
mkdir -p "$HOME/.claude"
printf 'untouched\n' > "$HOME/.claude/settings.json"
ln -s "$temporary/other-checkout" "$HOME/.config"
if sh "$repo/install.sh" > /dev/null 2>&1; then exit 1; fi
[ ! -L "$HOME/.claude/settings.json" ]
[ "$(cat "$HOME/.claude/settings.json")" = untouched ]
[ -z "$(find "$HOME" -name '*.dotfiles-backup.*' -print)" ]

export HOME="$temporary/failure-home"
mkdir -p "$HOME/.config/nvim" "$temporary/bin"
printf 'restore me\n' > "$HOME/.config/nvim/init.lua"
cat > "$temporary/bin/ln" <<'MOCK'
#!/bin/sh
case "$3" in
    */nvim/init.lua) exit 1 ;;
    *) exec /bin/ln "$@" ;;
esac
MOCK
chmod +x "$temporary/bin/ln"
if PATH="$temporary/bin:$PATH" sh "$repo/install.sh" > /dev/null 2>&1; then exit 1; fi
[ ! -L "$HOME/.config/nvim/init.lua" ]
[ "$(cat "$HOME/.config/nvim/init.lua")" = 'restore me' ]

# Do not replace source files with links to themselves.
export HOME="$temporary/same-location-home"
mkdir -p "$HOME/.config/nvim"
cp "$repo/install.sh" "$HOME/.config/install.sh"
printf 'source stays\n' > "$HOME/.config/nvim/init.lua"
sh "$HOME/.config/install.sh" > "$temporary/same-location"
[ ! -L "$HOME/.config/nvim/init.lua" ]
[ "$(cat "$HOME/.config/nvim/init.lua")" = 'source stays' ]

if sh "$repo/install.sh" --unknown > /dev/null 2>&1; then exit 1; fi
if sh "$repo/install.sh" --dry-run extra > /dev/null 2>&1; then exit 1; fi
printf 'PASS: dry-run, links, backups, repeat install, shared edits, new files, repository relocation, XDG, parent checks, rollback, source protection\n'
