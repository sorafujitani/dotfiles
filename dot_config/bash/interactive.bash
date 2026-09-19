# Source from ~/.bashrc. Bash 4+ is recommended for ble.sh autosuggestions.
[[ $- == *i* ]] || return 0
[[ ${_DOTFILES_BASH_LOADED-} == "$$" ]] && return 0
_DOTFILES_BASH_LOADED=$$

HISTSIZE=20000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth
shopt -s histappend cmdhist checkwinsize
set -o emacs
[[ ! -t 0 ]] || stty -ixon -ixoff 2>/dev/null

# Load command/option completions installed by the Linux package manager.
if ! declare -F _completion_loader >/dev/null && ! declare -F _comp_load >/dev/null; then
  for _dotfiles_completion in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
    if [[ -r $_dotfiles_completion ]]; then
      source "$_dotfiles_completion"
      break
    fi
  done
  unset _dotfiles_completion
fi

bind 'set bell-style none'
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\C-r": reverse-search-history'

export FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS:---height=60% --layout=reverse --border --info=inline}

# Use the editor available on this machine, without a macOS-specific path.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
elif command -v vim >/dev/null 2>&1; then
  export EDITOR=vim
fi

# ble.sh provides history suggestions, completion menus and session sharing.
if [[ ! ${BLE_VERSION-} && -r ${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh && $TERM != dumb ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" --attach=none
fi
if [[ ${BLE_VERSION-} ]]; then
  bleopt highlight_syntax=
  bleopt highlight_filename=
  bleopt highlight_variable=
  bleopt history_share=1
  bleopt complete_auto_history=1
  bleopt complete_auto_complete_opts=syntax-disabled
  bleopt edit_bell=
  ble-bind -f up history-search-backward
  ble-bind -f down history-search-forward
  if command -v fzf >/dev/null 2>&1; then
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
    # Use fzf for ordinary Tab completion, including files and directories.
    ble-import -d integration/fzf-menu
  fi
  ble-attach
else
  # Preserve existing prompt hooks and their exit status; never rewrite history.
  _dotfiles_history_sync() {
    local previous_status=$?
    history -a
    history -n
    return "$previous_status"
  }
  if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == 'declare -a '* ]]; then
    PROMPT_COMMAND=(_dotfiles_history_sync "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="_dotfiles_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  fi
  # fzf >= 0.48 embeds shell integration; older packages ship a separate file.
  if command -v fzf >/dev/null 2>&1; then
    if _dotfiles_fzf_init=$(fzf --bash 2>/dev/null); then
      eval "$_dotfiles_fzf_init"
    else
      for _dotfiles_fzf_keys in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/key-bindings.bash; do
        if [[ -r $_dotfiles_fzf_keys ]]; then
          source "$_dotfiles_fzf_keys"
          break
        fi
      done
    fi
    unset _dotfiles_fzf_init _dotfiles_fzf_keys
  fi
fi
