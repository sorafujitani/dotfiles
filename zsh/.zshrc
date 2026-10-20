# general
unsetopt nomatch
setopt share_history
# history 強化: ファイル保存は大きく、メモリ(HISTSIZE)は autosuggestions の
# 同期検索コストを抑えるため 20000 に留める (async 無効の前提を崩さない)
HISTSIZE=20000
SAVEHIST=100000
setopt hist_ignore_all_dups hist_reduce_blanks hist_ignore_space
export FUNCNEST=100
export EDITOR=nvim
autoload -U add-zsh-hook

# 描画安定化 (wezterm の damage/render に余計な trigger を渡さない)
# 1. /etc/zshrc が setopt BEEP を入れるので明示的に打ち消す
#    bell escape は visual bell を発火させて render path を一瞬奪う
unsetopt BEEP HIST_BEEP LIST_BEEP
# 2. ctrl-S/Q の flow control を無効化
#    IME や Karabiner 経由の誤爆で出力が止まり、wezterm 側のマウス wake で
#    解凍されたように見える挙動を排除する
[[ -t 0 ]] && stty -ixon -ixoff 2>/dev/null

# 重複 PATH/FPATH 自動排除(再評価コスト削減)
typeset -U path PATH fpath FPATH

# zsh cache directory
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# zsh-autosuggestions パフォーマンス設定 (load 前に export)
# MANUAL_REBIND=1 は precmd ごとに widget を再wrap し、他の widget wrapper と
# 競合して打鍵時に ZLE の描画が一瞬止まる現象を起こすため使わない。
#
# ZSH_AUTOSUGGEST_USE_ASYNC=1 は zpty 経由で別 process が async fetch し、
# 完了時に zle reset-prompt を別文脈から呼ぶため、コマンド出力中に prompt 再描画 escape が
# 割り込んで wezterm の damage 統合が乱れるケースがある。HISTSIZE=2000 と十分小さく
# 同期取得でも体感差がないため、async を切って描画起点を main thread に揃える。
# ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(history)
# precmd hook は 1 本に統合する
# 個別登録だと内部で fork した sub-hook (autosuggestions async, OSC 0 emit など) が
# コマンド出力中に latent flush され、wezterm の damage track と race することがあるため。
_precmd_combined() {
    # prompt 文字列
    local nix_prefix=""
    if [[ -n "${IN_NIX_SHELL:-}" ]]; then
        if [[ -n "${name:-}" ]]; then
            nix_prefix="(nix:${name}) "
        else
            nix_prefix="(nix) "
        fi
    fi
    PS1="${nix_prefix}%1~ $ "

    # tab title (OSC 0)
    # 出力前に shell が prompt を出すタイミングでのみ吐く (precmd 内に集約)
    print -n "\033]0;${PWD##*/}\007"
}
add-zsh-hook precmd _precmd_combined

[[ -f ~/.secrets ]] && source ~/.secrets

# path (brew shellenv static expansion)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

export PATH="$HOME/.cargo/bin:$PATH"

# mysql
export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/mysql-client@8.0/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql-client@8.0/include"
# mysql の pkgconfig を先頭に置き、/usr/lib/pkgconfig が mysql を上書きしないようにする
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql-client@8.0/lib/pkgconfig:/usr/lib/pkgconfig"

export ACLOCAL_PATH=/usr/local/share/aclocal/:$ACLOCAL_PATH

# nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if [ -d "/nix/var/nix/profiles/default/bin" ] && [[ ! "$PATH" == *"/nix/var/nix/profiles/default/bin"* ]]; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi

export NIX_CONFIG="experimental-features = nix-command flakes"

# bun global bin
export PATH="$HOME/.bun/bin:$PATH"

# source 対象を事前コンパイルする。元ファイル更新時だけ .zwc を再生成する。
_zsh_compile_script() {
    local script="$1"
    [[ -r "$script" ]] || return
    [[ -f "$script.zwc" && ! "$script" -nt "$script.zwc" ]] ||
        zcompile -R "$script" 2>/dev/null
}

_zsh_source_compiled() {
    local script="$1"
    _zsh_compile_script "$script"
    source "$script"
}

# tools (init 出力をキャッシュ化して eval string parse コストを削減)
# 実体の path・binary mtime・設定ファイルのいずれかが変わった時だけ再生成する。
# Nix profile の symlink は mtime が固定なので、解決後 path も cache key に含める。
_zsh_cache_eval() {
    local name="$1" cmd="$2" dependency="$3"; shift 3
    local cache="$ZSH_CACHE_DIR/$name.zsh"
    local cache_key="$cache.key"
    local cache_tmp="$cache.tmp.$$"
    local src="${commands[$cmd]:A}"
    local signature="$src ${(q)@}"
    [[ -z "$src" ]] && return
    if [[ ! -s "$cache" || ! -f "$cache_key" || "$(<"$cache_key")" != "$signature" || \
          "$src" -nt "$cache" || ( -n "$dependency" && "$dependency" -nt "$cache" ) ]]; then
        if "$@" >| "$cache_tmp" 2>/dev/null; then
            mv -f "$cache_tmp" "$cache"
            print -r -- "$signature" >| "$cache_key"
        else
            rm -f "$cache_tmp"
        fi
    fi
    [[ -s "$cache" ]] || return
    _zsh_compile_script "$cache"
    source "$cache"
}

# sheldon が source する script も先にコンパイルしておく。
_zsh_compile_script "$HOME/.local/share/sheldon/repos/github.com/romkatv/zsh-defer/zsh-defer.plugin.zsh"
_zsh_compile_script "$HOME/.local/share/sheldon/repos/github.com/zsh-users/zsh-completions/zsh-completions.plugin.zsh"

_zsh_cache_eval mise    mise    "" mise activate zsh
_zsh_cache_eval sheldon sheldon "$HOME/.config/sheldon/plugins.toml" sheldon source
_zsh_cache_eval zoxide  zoxide  "" zoxide init zsh
_zsh_cache_eval direnv  direnv  "" direnv hook zsh

export PATH="$PATH:$HOME/go/bin"

# nix profile を GNU tools / global ruby の default に。
# sheldon 等の PATH 再構築より後、rv の起動時フックより前に置く
# (project 内では rv / mise が更に前へ prepend して勝つ)
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

# Ruby プロジェクトでない時は即 return して `rv shell env zsh` の外部プロセス起動を避ける
_rv_autoload_hook () {
    [[ -f .ruby-version || -f Gemfile || -f .rvmrc || ( -f .tool-versions && -n ${"$(<.tool-versions)"[(r)ruby*]} ) ]] || return 0
    eval "$(/opt/homebrew/bin/rv shell env zsh)"
}
add-zsh-hook chpwd _rv_autoload_hook
_rv_autoload_hook

# grok — full TUI by default (theme/bg from ~/.grok/config.toml)
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
# minimal mode: terminal-native colors only (ignores theme)
alias grok-min='command grok --minimal'

# user-local commands and secret-loading wrappers take final precedence
export PATH="$HOME/.local/bin:$HOME/.config/scripts:$PATH"

# completion & keybindings
# Zeno を読み込んだ既存 shell でこのファイルを source した場合、遅延初期化より
# 先に旧 widget が呼ばれると、削除済みの function file を探して入力が壊れる。
# 旧 binding が実際に残っている時だけ標準 widget へ戻し、下で zshctl を再設定する。
if bindkey | command grep -q 'zeno-'; then
    bindkey ' ' self-insert
    bindkey '^M' accept-line
    bindkey '^I' expand-or-complete
    bindkey '^R' history-incremental-search-backward
    bindkey -r '^Xx' '^X ' '^X^M' '^X^Z' '^Xp' '^Xs' '^X^R' 2>/dev/null
fi

# 初回 prompt の表示後に compinit と依存 plugin をまとめて読み込む。
# dump があり fpath の構成が変わっていなければ -C で audit/dump 再生成を省略する。
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump"

_zsh_deferred_completion_init() {
    local rebuild_dump=0 completion_dir
    autoload -Uz compinit

    if [[ ! -s "$ZSH_COMPDUMP" ]]; then
        rebuild_dump=1
    else
        for completion_dir in $fpath; do
            if [[ -d "$completion_dir" && "$completion_dir" -nt "$ZSH_COMPDUMP" ]]; then
                rebuild_dump=1
                break
            fi
        done
    fi

    if (( rebuild_dump )); then
        compinit -d "$ZSH_COMPDUMP"
    else
        compinit -C -d "$ZSH_COMPDUMP"
    fi
    _zsh_compile_script "$ZSH_COMPDUMP"

    local fzf_tab_plugin="$HOME/.local/share/sheldon/repos/github.com/Aloxaf/fzf-tab/fzf-tab.plugin.zsh"
    [[ -f "$fzf_tab_plugin" ]] && _zsh_source_compiled "$fzf_tab_plugin"

    local autosuggest_plugin="$HOME/.local/share/sheldon/repos/github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [[ -f "$autosuggest_plugin" ]] && _zsh_source_compiled "$autosuggest_plugin"

    local zshctl_bin="$HOME/.nix-profile/bin/zshctl"
    local zshctld_bin="$HOME/.nix-profile/bin/zshctld"
    local zshctl_loader="$HOME/.nix-profile/share/zshctl/zshctl.zsh"
    if [[ -x "$zshctl_bin" && -x "$zshctld_bin" && -r "$zshctl_loader" ]]; then
        # herdr 等の親 process から ZSHCTL_BOOTSTRAPPED=1 が export 継承されると
        # zshctl-bootstrap.zsh が即 return し、widget 未登録のまま Enter だけ
        # safe wrapper に繋がって nv/evsh が生コマンド扱いになる。
        # この shell に widget が無い時だけ bootstrap guard を外して再初期化する。
        # zle -l は autosuggest wrap 後に
        # `zshctl-auto-snippet (_zsh_autosuggest_bound_...)` 形式になるので
        # 行末固定ではなく prefix で見る。
        if ! zle -l 2>/dev/null | command grep -q '^zshctl-auto-snippet'; then
            unset ZSHCTL_BOOTSTRAPPED ZSHCTL_LOADED
            # 親 shell の session id を子 pane で再利用しない
            unset ZSHCTL_SESSION_ID ZSHCTL_HISTORY_SESSION_ID
        fi
        source "$zshctl_loader"
        hash zshctl="$zshctl_bin"
        hash zshctld="$zshctld_bin"

        if (( $+functions[zshctl-bind-default-keys] )) && zle -l 2>/dev/null | command grep -q '^zshctl-auto-snippet'; then
            zshctl-bind-default-keys

            # zshctl-auto-snippet は候補なし時に押下キーを self-insert する。
            # Enter から呼ぶ場合は CR を BUFFER へ入れず、そのまま accept-line する。
            _zshctl_noop() { : }
            zle -N _zshctl_noop
            _zshctl_safe_auto_snippet_and_accept_line() {
                local ZSHCTL_AUTO_SNIPPET_FALLBACK=_zshctl_noop
                zle zshctl-auto-snippet
                zle accept-line
            }
            zle -N _zshctl_safe_auto_snippet_and_accept_line
            bindkey '^M' _zshctl_safe_auto_snippet_and_accept_line
        fi
    fi

    unfunction _zsh_deferred_completion_init
}

if (( $+functions[zsh-defer] )); then
    zsh-defer _zsh_deferred_completion_init
else
    _zsh_deferred_completion_init
fi

# EDITOR=nvim だと main keymap が viins に倒れるため明示的に emacs に固定
bindkey -e

# fzf-tab 設定
zstyle ':fzf-tab:*' continuous-trigger 'tab'
zstyle ':fzf-tab:*' fzf-bindings 'esc:abort'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-pad 4
zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# ディレクトリ補完 (cd) で eza/ls の中身プレビュー
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'if [[ -d $realpath ]]; then ls -la --color=always "$realpath" 2>/dev/null || ls -la "$realpath"; fi'
# git checkout のブランチ説明
zstyle ':fzf-tab:complete:git-(add|diff|restore|checkout):*' fzf-preview \
  'git diff --color=always -- $word 2>/dev/null | head -200'

# functions
# _set_tab_title は _precmd_combined に統合済み (precmd hook の個別登録を避けるため)

# fzf 全体デフォルト
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border --info=inline --bind=ctrl-/:toggle-preview'
(( $+commands[fd] )) && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# ghq + fzf navigation (~/ghq/<host>/<owner>/<repo>)
ghq-path() {
    ghq list --full-path | fzf
}

dev() {
    local moveto
    moveto=$(ghq-path) || return 1
    [[ -z "$moveto" ]] && return 1
    cd "$moveto" || return 1
    if [[ -n "${TMUX:-}" ]]; then
        local repo_name="${moveto##*/}"
        tmux rename-session "${repo_name//./-}"
    fi
}

# ghq-fzf: 入力中のコマンドラインを ghq 選択結果に置き換えて即実行 (Ctrl-G)
# README があれば bat で先頭80行プレビュー、無ければ ls -la を表示
ghq-fzf() {
    local src
    src=$(ghq list | fzf --preview '
        d="$(ghq root)/{}"
        if [ -f "$d/README.md" ]; then
            bat --color=always --style=header,grid --line-range :80 "$d/README.md"
        elif [ -f "$d/README.markdown" ]; then
            bat --color=always --style=header,grid --line-range :80 "$d/README.markdown"
        elif [ -f "$d/README" ]; then
            bat --color=always --style=header,grid --line-range :80 "$d/README"
        else
            ls -la "$d"
        fi
    ')
    if [[ -n "$src" ]]; then
        BUFFER="cd $(ghq root)/$src"
        zle accept-line
    fi
    zle -R -c
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

# gwq-fzf: 任意リポの git worktree を横断検索して cd (Ctrl-O)
# 命名規則 <repo>=<branch> のディレクトリを find で抽出
# (wezterm default が ^X / ^W を奪うため ^O を使用)
gwq-fzf() {
    local target
    target=$(find "${GHQ_ROOT:-$HOME/ghq}" -mindepth 4 -maxdepth 4 -type d -name '*=*' 2>/dev/null \
        | fzf --preview 'cd {} && git status -sb 2>/dev/null | head -30')
    if [[ -n "$target" ]]; then
        BUFFER="cd $target"
        zle accept-line
    fi
    zle -R -c
}
zle -N gwq-fzf
bindkey '^o' gwq-fzf

# fbr: 現在リポのブランチを fzf で選んで checkout (コマンドとして使用)
# `fbr` をプロンプトで実行。bindkey はwezterm default と衝突しないキーが少ないので未割当。
fbr() {
    local branch
    branch=$(git branch -a --color=never 2>/dev/null \
        | sed 's|^[* ]*||;s|^remotes/origin/||' \
        | grep -v '^HEAD' \
        | sort -u \
        | fzf --preview 'git log --color=always --oneline -20 {} 2>/dev/null')
    [[ -n "$branch" ]] && git checkout "$branch"
}

# Secretive (Secure Enclave) SSH agent for git signing
export SSH_AUTH_SOCK="/Users/fujitanisora/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
