;;; init.el --- Entry point -*- lexical-binding: t; -*-

;;; Commentary:
;; Emacs 31 向け。package.el + use-package で管理し、設定は lisp/ 配下のモジュールに分ける。
;;   init-core        基本動作・ファイル・編集
;;   init-ui          テーマ・フォント・モードライン
;;   init-completion  vertico / consult / corfu
;;   init-lsp         eglot / tree-sitter / フォーマッタ / flymake
;;   init-lang        言語モード
;;   init-git         magit / diff-hl
;;   init-tools       ターミナル・ファイラ・デバッガ・Copilot
;;   init-keys        ユーザー定義キー (C-c prefix) の一覧

;;; Code:

(when (version< emacs-version "30")
  (error "This config requires Emacs 30 or later (current: %s)" emacs-version))

;;; package.el
(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1))
      package-install-upgrade-built-in t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;;; use-package
(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer nil
      use-package-expand-minimally t
      use-package-vc-prefer-newest t)

;;; modules
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'init-core)
(require 'init-ui)
(require 'init-completion)
(require 'init-lsp)
(require 'init-lang)
(require 'init-git)
(require 'init-tools)
(require 'init-keys)

;;; custom
(setq custom-file (expand-file-name "custom.el" my/cache-dir))
(load custom-file 'noerror 'nomessage)

(provide 'init)
;;; init.el ends here
