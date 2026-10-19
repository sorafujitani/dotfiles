#!/usr/bin/env bash
# Test root setup and real Vim in disposable homes; no actual sudo/root writes.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
vim_command=$(command -v vim)
export HOME="$test_dir/root"
export TEST_ALICE_HOME="$test_dir/alice's home"
export TEST_BOB_HOME="$test_dir/bob home"
mkdir -p "$HOME" "$TEST_ALICE_HOME" "$TEST_BOB_HOME" "$test_dir/bin"
export PATH="$test_dir/bin:$PATH"
printf '#!/bin/sh\nprintf "%%s\\n" "${TEST_UID:-0}"\n' > "$test_dir/bin/id"
cat > "$test_dir/bin/getent" <<'GETENT'
#!/bin/sh
[ "$1" = passwd ] || exit 1
case "$2" in
  alice) user_home=$TEST_ALICE_HOME ;;
  bob) user_home=$TEST_BOB_HOME ;;
  *) exit 2 ;;
esac
printf '%s:x:1000:1000::%s:/bin/bash\n' "$2" "$user_home"
GETENT
chmod +x "$test_dir/bin/"*
# Use the published config, not unrelated local edits to vim/.vimrc.
git -C "$repo" show HEAD:vim/.vimrc > "$test_dir/published-vimrc"
for user in alice bob; do
  if [[ $user == alice ]]; then user_home=$TEST_ALICE_HOME; else user_home=$TEST_BOB_HOME; fi
  cp "$test_dir/published-vimrc" "$user_home/.vimrc"
  printf '\nlet g:sudo_caller = "%s"\n' "$user" >> "$user_home/.vimrc"
done
printf 'let g:root_keep = 1\n' > "$HOME/.vimrc"
for _attempt in 1 2; do
  sh "$repo/bash/setup-root-vim.sh" "$repo/vim/sudo.vim"
done
[[ $(grep -c '^" dotfiles sudo vim$' "$HOME/.vimrc") == 1 ]]
backups=("$HOME"/.vimrc.before-dotfiles-sudo-vim.*)
[[ ${#backups[@]} == 1 && $(< "${backups[0]}") == 'let g:root_keep = 1' ]]
[[ -z $(find "$HOME" -name '.sudo-vim.*' -print) ]]
printf 'if true; then\n  echo "hello"\nfi\n' > "$test_dir/example.sh"
export TEST_VIM_ERRORS="$test_dir/vim-errors"
cat > "$test_dir/check.vim" <<'VIM'
call assert_equal(1, g:root_keep)
call assert_equal('', v:errmsg)
if $SUDO_USER ==# 'alice' || $SUDO_USER ==# 'bob'
  call assert_equal($SUDO_USER, get(g:, 'sudo_caller', ''))
  call assert_equal(1, exists('g:syntax_on'))
  call assert_equal('sh', &filetype)
  call assert_equal('sh', &syntax)
  call assert_equal('111', synIDattr(synIDtrans(synID(1, 1, 1)), 'fg', 'cterm'))
else
  call assert_false(exists('g:sudo_caller'))
endif
if !empty(v:errors)
  call writefile(v:errors, $TEST_VIM_ERRORS)
  cquit
endif
qa!
VIM
for caller in alice bob root unknown ''; do
  SUDO_USER=$caller "$vim_command" -Nu "$HOME/.vimrc" -i NONE -n -es \
    "$test_dir/example.sh" -S "$test_dir/check.vim" || {
      [[ ! -f $TEST_VIM_ERRORS ]] || grep . "$TEST_VIM_ERRORS"
      exit 1
    }
done

# Back up symlinks without changing the managed target.
export HOME="$test_dir/symlink-root"
mkdir -p "$HOME"
printf 'let g:managed_root = 1\n' > "$test_dir/managed-vimrc"
ln -s "$test_dir/managed-vimrc" "$HOME/.vimrc"
sh "$repo/bash/setup-root-vim.sh" "$repo/vim/sudo.vim"
[[ ! -L $HOME/.vimrc ]]
[[ $(< "$test_dir/managed-vimrc") == 'let g:managed_root = 1' ]]
backups=("$HOME"/.vimrc.before-dotfiles-sudo-vim.*)
[[ ${#backups[@]} == 1 && -L ${backups[0]} ]]

# Keep Vim's alternative existing user config instead of shadowing it.
export HOME="$test_dir/alternative-root"
mkdir -p "$HOME/.vim"
printf 'let g:existing_root = 1\n' > "$HOME/.vim/vimrc"
sh "$repo/bash/setup-root-vim.sh" "$repo/vim/sudo.vim"
[[ ! -e $HOME/.vimrc ]]
grep -q '^let g:existing_root = 1$' "$HOME/.vim/vimrc"

export HOME="$test_dir/unprivileged"
mkdir -p "$HOME"
if TEST_UID=1000 sh "$repo/bash/setup-root-vim.sh" "$repo/vim/sudo.vim"; then exit 1; fi
[[ ! -e $HOME/.vimrc ]]
printf '%s\n' 'PASS: sudo-user syntax/colors, root config backup, repeat, symlinks and non-sudo Vim'
