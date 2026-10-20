;;; init-core.el --- Core defaults -*- lexical-binding: t; -*-

;;; Commentary:
;; 外部パッケージに依存しない基本設定と、PATH・生成物の置き場所。

;;; Code:

;;; 生成物を ~/.cache/emacs 配下へ
(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "etc" my/cache-dir)
        no-littering-var-directory (expand-file-name "var" my/cache-dir))
  :config
  (no-littering-theme-backups))

;;; macOS GUI で zsh の PATH を引き継ぐ (nix は .zshrc で読むので -i が要る)
(use-package exec-path-from-shell
  :if (or (daemonp) (memq window-system '(mac ns)))
  :demand t
  :init
  (setq exec-path-from-shell-arguments '("-l" "-i")
        exec-path-from-shell-variables '("PATH" "MANPATH" "GOPATH" "SSH_AUTH_SOCK"))
  :config
  (exec-path-from-shell-initialize))

;;; 文字コード
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))

;;; 基本動作
(setq use-short-answers t
      ring-bell-function #'ignore
      confirm-kill-emacs nil
      confirm-kill-processes nil
      enable-recursive-minibuffers t
      read-process-output-max (* 4 1024 1024)
      kill-ring-max 1000
      sentence-end-double-space nil
      require-final-newline t
      load-prefer-newer t
      vc-follow-symlinks t
      help-window-select t
      echo-keystrokes 0.1
      warning-minimum-level :error)
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 100
              truncate-lines nil)

;;; ファイル: バックアップ・ロックは作らず、訪問中ファイルは一定間隔で自動保存する
(setq make-backup-files nil
      create-lockfiles nil
      auto-save-default nil
      auto-save-visited-interval 1
      delete-by-moving-to-trash t)
(auto-save-visited-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

;;; 履歴・位置
(savehist-mode 1)
(setq history-length 1000
      savehist-additional-variables '(search-ring regexp-search-ring extended-command-history))
(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 300
      recentf-exclude `(,(regexp-quote my/cache-dir) "/tmp/" "\\.gz$"))

;;; 編集
(delete-selection-mode 1)
(electric-pair-mode 1)
(setq electric-pair-skip-whitespace nil)
(global-subword-mode 1)
(repeat-mode 1)
(setq-default show-trailing-whitespace nil)

;;; 行末空白は変更行だけ削る
(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

;;; スクロール
(setq scroll-conservatively 101
      scroll-margin 4
      scroll-preserve-screen-position t
      mouse-wheel-progressive-speed nil)
(pixel-scroll-precision-mode 1)

;;; 組込み minor mode
(which-key-mode 1)
(setq which-key-idle-delay 0.4
      which-key-sort-order 'which-key-key-order-alpha)
(editorconfig-mode 1)
(winner-mode 1)

;;; ヘルプを見やすく
(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-command]  . helpful-command)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key]      . helpful-key)
         ([remap describe-symbol]   . helpful-symbol)))

;;; undo 履歴を木で辿る
(use-package vundo
  :bind ("C-x u" . vundo)
  :custom (vundo-glyph-alist vundo-unicode-symbols))

;;; direnv (nix 開発環境を自動反映)
(use-package envrc
  :if (executable-find "direnv")
  :hook (after-init . envrc-global-mode))

(provide 'init-core)
;;; init-core.el ends here
