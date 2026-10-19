" Reuse the invoking user's configuration when Vim runs through sudo.
if empty($SUDO_USER) || $SUDO_USER ==# 'root'
  finish
endif
let s:passwd = system('getent passwd ' . shellescape($SUDO_USER))
if v:shell_error
  finish
endif
let s:fields = split(substitute(s:passwd, '\n$', '', ''), ':', 1)
if len(s:fields) != 7 || s:fields[0] !=# $SUDO_USER
  finish
endif
let s:vimrc = s:fields[5] . '/.vimrc'
if filereadable(s:vimrc) && resolve(s:vimrc) !=# resolve(expand('$MYVIMRC'))
  execute 'source ' . fnameescape(s:vimrc)
endif
