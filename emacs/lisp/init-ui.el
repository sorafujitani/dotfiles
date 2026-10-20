;;; init-ui.el --- Theme, fonts, modeline -*- lexical-binding: t; -*-

;;; Commentary:
;; 見た目まわり。フォントは GUI フレーム生成時にだけ設定する (daemon 対応)。

;;; Code:

;;; フォント
(defvar my/font-family "Hack Nerd Font Mono")
(defvar my/font-height 140)
(defvar my/font-family-ja "Hiragino Sans")

(defun my/setup-fonts (&optional frame)
  "FRAME にフォントを設定する。"
  (when (display-graphic-p frame)
    (with-selected-frame (or frame (selected-frame))
      (when (find-font (font-spec :family my/font-family))
        (set-face-attribute 'default nil :family my/font-family :height my/font-height)
        (set-face-attribute 'fixed-pitch nil :family my/font-family))
      (when (find-font (font-spec :family my/font-family-ja))
        (dolist (charset '(japanese-jisx0208 japanese-jisx0212 katakana-jisx0201 cp932))
          (set-fontset-font t charset (font-spec :family my/font-family-ja))))
      ;; 絵文字
      (when (find-font (font-spec :family "Apple Color Emoji"))
        (set-fontset-font t 'emoji (font-spec :family "Apple Color Emoji") nil 'prepend)))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/setup-fonts)
  (add-hook 'after-init-hook #'my/setup-fonts))

;;; テーマ
(use-package doom-themes
  :demand t
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  :config
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

;; ターミナルではテーマの背景色を塗らず、端末側の背景 (透過含む) をそのまま使う
(defun my/transparent-terminal-background (&optional frame)
  "FRAME がターミナルなら背景を未指定にする。"
  (unless (display-graphic-p frame)
    (dolist (face '(default line-number line-number-current-line fringe))
      (set-face-background face "unspecified-bg" frame))))

(add-hook 'after-make-frame-functions #'my/transparent-terminal-background)
(add-hook 'window-setup-hook #'my/transparent-terminal-background)

;;; アイコン (Nerd Font は Hack Nerd Font を流用)
(use-package nerd-icons
  :custom (nerd-icons-font-family my/font-family))

;;; モードライン
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 3)
  (doom-modeline-buffer-file-name-style 'relative-to-project)
  (doom-modeline-buffer-encoding 'nondefault)
  (doom-modeline-vcs-max-length 24)
  (doom-modeline-lsp t)
  (doom-modeline-env-version nil)
  (doom-modeline-minor-modes nil))

;;; 行番号 
(setq display-line-numbers-type t
      display-line-numbers-width 3
      display-line-numbers-widen t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;;; カーソル行・列
(global-hl-line-mode 1)
(column-number-mode 1)
(blink-cursor-mode -1)
(setq-default cursor-in-non-selected-windows nil)

;;; 括弧
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-context-when-offscreen 'overlay)
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;; TODO/FIXME を強調
(use-package hl-todo
  :hook ((prog-mode text-mode) . hl-todo-mode))

;;; インデントガイド
(use-package indent-bars
  :hook ((prog-mode yaml-ts-mode) . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t)
  (indent-bars-prefer-character t)
  (indent-bars-width-frac 0.15)
  (indent-bars-color '(highlight :face-bg t :blend 0.25))
  (indent-bars-highlight-current-depth '(:blend 0.5)))

;;; 操作後にカーソル行を一瞬光らせる
(use-package pulsar
  :hook (after-init . pulsar-global-mode)
  :custom
  (pulsar-pulse t)
  (pulsar-delay 0.04)
  (pulsar-iterations 8)
  :config
  (dolist (fn '(ace-window avy-goto-char-timer consult-line consult-imenu
                xref-find-definitions xref-go-back))
    (add-to-list 'pulsar-pulse-functions fn)))

;;; タイトル・各種表示
(setq frame-title-format '("%b" (:eval (when (buffer-file-name) (concat " — " (abbreviate-file-name default-directory)))))
      window-divider-default-right-width 1
      window-divider-default-places 'right-only)
(window-divider-mode 1)
(setq split-width-threshold 160
      split-height-threshold nil)

;;; 長い行の折り返し
(add-hook 'text-mode-hook #'visual-line-mode)

(provide 'init-ui)
;;; init-ui.el ends here
