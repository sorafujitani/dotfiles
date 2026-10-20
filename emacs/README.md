# Emacs Configuration

Emacs 31 向け。組込み機能 (eglot / tree-sitter / flymake / project / which-key) を軸に、
補完 UI・Git・ターミナルだけパッケージで足す。キーバインドは Emacs 標準を変えない。

## Environment

- macOS, Emacs 31.1 (`brew install --cask emacs-app`)
- 生成物は `~/.cache/emacs/` に置く (`~/.config/emacs/` は設定ファイルだけ)

## Setup

dotfilesリポジトリのルートで実行します。既存設定は先にバックアップしてください。

```sh
brew install --cask emacs-app          # Emacs.app
brew install libtool libvterm aspell   # vterm のビルド / スペルチェック
brew install --cask font-hack-nerd-font
umask 077
mkdir -p "$HOME/.config"
cp -Ri emacs "$HOME/.config/"
emacs                                  # 初回はパッケージを自動インストール
```

LSP サーバは home-manager / brew / mise で導入済みのものを使う:
gopls, rust-analyzer, typescript-language-server, lua-language-server, ruby-lsp, ty, nil, zls,
marksman。MoonBit は moonbit-ts-mode が `moon lsp` を使う。フォーマッタは gofumpt, biome, stylua, nixfmt, rustfmt, ruff。

初回のみ:

- tree-sitter grammar: 対象ファイルを開くと自動で取得・ビルドする (git と cc が必要)
- Copilot: `M-x copilot-install-server` → `M-x copilot-login`

## Layout

| File | Role |
|---|---|
| `early-init.el` | GC、キャッシュ先、フレーム装飾 |
| `init.el` | package.el / use-package、モジュール読込 |
| `lisp/init-core.el` | 基本動作、PATH、自動保存、履歴 |
| `lisp/init-ui.el` | doom-themes, doom-modeline, フォント, 行番号 |
| `lisp/init-completion.el` | vertico, orderless, consult, embark, corfu, cape, yasnippet |
| `lisp/init-lsp.el` | eglot, treesit, expreg, flymake, apheleia, dape |
| `lisp/init-lang.el` | 言語モード (*-ts-mode 優先) |
| `lisp/init-git.el` | magit, diff-hl, git-timemachine, git-link, project |
| `lisp/init-tools.el` | vterm, dirvish, avy, ace-window, puni, multiple-cursors, copilot |
| `lisp/init-keys.el` | `C-c` 配下の補助コマンドと which-key 見出し |

## Keys

標準キー (`C-x C-f`, `C-x b`, `M-x`, `C-s`, `C-x o` ...) はそのまま。追加分の prefix:

| Prefix | 内容 |
|---|---|
| `M-s` | consult 検索 (`M-s g` ripgrep, `M-s d` fd, `M-s l` line) |
| `M-g` | consult 移動 (`M-g i` imenu, `M-g f` flymake) / avy |
| `C-x p` | project.el (`C-x p p` 切替, `C-x p f` ファイル, `C-x p b` バッファ) |
| `C-c l` | eglot (`a` action, `r` rename, `o` imports, `h` doc) |
| `C-c !` | flymake 一覧。`M-n` / `M-p` で次・前の診断 |
| `C-x g` / `C-c g` | magit-status / magit-file-dispatch |
| `C-c v` | git-timemachine (`t`), git-link (`l`), log grep (`g`) |
| `C-c t` | vterm toggle (プロジェクト単位) |
| `C-c o` / `C-x d` | dirvish-side / dirvish |
| `C-x C-a` | dape (gud と同じ prefix) |
| `M-o` | ace-window |
| `C-.` / `C-;` | embark-act / embark-dwim |
| `C-=` | expreg (構文木でリージョン拡張) |
| `C-c f` | apheleia-format-buffer (保存時は自動) |
| `C-c c` | copilot-complete。`C-<tab>` で受け入れ |

## Maintenance

- パッケージ更新: `M-x package-upgrade-all`
- 設定の再読込: `C-c r`
- 設定ファイルを開く: `C-c e`
