#!/bin/sh
# Run as root with its HOME: preserve its vimrc and append the sudo-user loader.
set -eu
[ "$#" -eq 1 ] && [ -s "$1" ] || { printf 'Usage: sh setup-root-vim.sh /path/to/sudo.vim\n' >&2; exit 2; }
[ "$(id -u)" -eq 0 ] || { printf 'Run with sudo -H or as root.\n' >&2; exit 1; }
: "${HOME:?HOME is required}"

vimrc=$HOME/.vimrc
if [ ! -e "$vimrc" ] && [ ! -L "$vimrc" ] && [ -f "$HOME/.vim/vimrc" ]; then
  vimrc=$HOME/.vim/vimrc
fi
[ ! -d "$vimrc" ] || { printf 'Vim config is a directory: %s\n' "$vimrc" >&2; exit 1; }
loader=$HOME/.vimrc.dotfiles-sudo.vim
staged=$(mktemp "$HOME/.sudo-vim.XXXXXX")
trap 'rm -f -- "$staged"' EXIT HUP INT TERM

if ! cmp -s "$1" "$loader"; then
  cp -- "$1" "$staged"
  chmod 644 "$staged"
  if [ -e "$loader" ] || [ -L "$loader" ]; then
    cp -Pp -- "$loader" "$loader.backup.$(date +%Y%m%d%H%M%S).$$"
  fi
  mv -f -- "$staged" "$loader"
fi

marker='" dotfiles sudo vim'
if [ -f "$vimrc" ] && grep -Fxq "$marker" "$vimrc"; then
  printf '[OK] sudo Vim loader already configured: %s\n' "$vimrc"
  exit 0
fi
rm -f -- "$staged"
staged=$(mktemp "$HOME/.sudo-vim.XXXXXX")
if [ -e "$vimrc" ] || [ -L "$vimrc" ]; then
  cp -pL -- "$vimrc" "$staged"
  backup=$vimrc.before-dotfiles-sudo-vim.$(date +%Y%m%d%H%M%S).$$
  cp -Pp -- "$vimrc" "$backup"
  printf '[SAVED] %s\n' "$backup"
else
  chmod 644 "$staged"
fi
printf '\n%s\n%s\n' "$marker" \
  "execute 'source ' . fnameescape(expand('~/.vimrc.dotfiles-sudo.vim'))" >> "$staged"
mv -f -- "$staged" "$vimrc"
printf '[OK] sudo Vim will load the invoking user\047s ~/.vimrc: %s\n' "$vimrc"
