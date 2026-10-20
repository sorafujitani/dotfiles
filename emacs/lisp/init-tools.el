;;; init-tools.el --- Terminal, file manager, navigation, AI -*- lexical-binding: t; -*-

;;; Commentary:
;; ターミナル (vterm)、ファイラ (dirvish)、ジャンプ (avy / ace-window)、Copilot。

;;; Code:

;;; ターミナル
(use-package vterm
  :commands (vterm vterm-other-window)
  :custom
  (vterm-always-compile-module t)
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  (vterm-shell (or (getenv "SHELL") "/bin/zsh"))
  :config
  (add-hook 'vterm-mode-hook (lambda () (setq-local global-hl-line-mode nil))))

(use-package vterm-toggle
  :bind (("C-c t" . vterm-toggle)
         ("C-c T" . vterm-toggle-cd))
  :custom
  (vterm-toggle-scope 'project)
  (vterm-toggle-fullscreen-p nil)
  :config
  ;; 下側に 30% の高さで出す
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                   (let ((buffer (get-buffer buffer-or-name)))
                     (with-current-buffer buffer
                       (or (equal major-mode 'vterm-mode)
                           (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (reusable-frames . visible)
                 (window-height . 0.3))))

;;; ファイラ (dired を拡張)
(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-auto-revert-buffer t)
  (dired-create-destination-dirs 'ask)
  :config
  ;; macOS の BSD ls は --group-directories-first を知らないので GNU ls を使う
  (when-let* ((gls (executable-find "gls")))
    (setq insert-directory-program gls)))

(use-package dirvish
  :hook (after-init . dirvish-override-dired-mode)
  :bind (("C-c o" . dirvish-side)
         ("C-x d" . dirvish)
         :map dirvish-mode-map
         ("a"   . dirvish-quick-access)
         ("f"   . dirvish-file-info-menu)
         ("y"   . dirvish-yank-menu)
         ("N"   . dirvish-narrow)
         ("^"   . dirvish-history-last)
         ("h"   . dirvish-history-jump)
         ("s"   . dirvish-quicksort)
         ("v"   . dirvish-vc-menu)
         ("TAB" . dirvish-subtree-toggle)
         ("M-f" . dirvish-history-go-forward)
         ("M-b" . dirvish-history-go-backward)
         ("M-l" . dirvish-ls-switches-menu)
         ("M-m" . dirvish-mark-menu)
         ("M-t" . dirvish-layout-toggle)
         ("M-s" . dirvish-setup-menu)
         ("M-e" . dirvish-emerge-menu)
         ("M-j" . dirvish-fd-jump))
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/" "Home")
     ("g" "~/ghq/github.com/" "ghq")
     ("c" "~/.config/" "config")
     ("d" "~/Downloads/" "Downloads")))
  (dirvish-mode-line-format '(:left (sort symlink) :right (omit yank index)))
  (dirvish-attributes '(nerd-icons file-time file-size collapse subtree-state vc-state git-msg))
  (dirvish-side-width 35)
  (dirvish-use-header-line 'global)
  (dirvish-subtree-state-style 'nerd)
  :config
  ;; extensions/ 配下は autoload されないので明示的に読む
  (let ((ext (expand-file-name "extensions" (file-name-directory (locate-library "dirvish")))))
    (when (file-directory-p ext)
      (add-to-list 'load-path ext)))
  (require 'dirvish-peek)
  (require 'dirvish-side)
  (dirvish-peek-mode 1)
  (dirvish-side-follow-mode 1))

;;; ジャンプ
(use-package avy
  :bind (("C-:" . avy-goto-char-timer)
         ("M-g c" . avy-goto-char-2)
         ("M-g w" . avy-goto-word-1)
         ("M-g l" . avy-goto-line)
         :map isearch-mode-map
         ("C-'" . avy-isearch))
  :custom
  (avy-timeout-seconds 0.3)
  (avy-all-windows t)
  (avy-background t))

(use-package ace-window
  :bind (("M-o" . ace-window)
         ([remap other-window] . ace-window))
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-scope 'frame)
  (aw-dispatch-always nil))

;; S-矢印 でウィンドウ移動
(windmove-default-keybindings)

;;; 括弧の編集 (M-( などの標準に加え、構造的な編集)
(use-package puni
  :hook ((prog-mode sgml-mode nxml-mode tex-mode) . puni-mode)
  :bind (:map puni-mode-map
              ("C-)" . puni-slurp-forward)
              ("C-(" . puni-slurp-backward)
              ("C-}" . puni-barf-forward)
              ("C-{" . puni-barf-backward)
              ("C-c s r" . puni-raise)
              ("C-c s s" . puni-splice)))

;;; 複数カーソル
(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-S-c C-S-c" . mc/edit-lines)))

;;; 集中モード
(use-package olivetti
  :bind ("C-c z" . olivetti-mode)
  :custom (olivetti-body-width 100))

;;; Copilot (初回は M-x copilot-install-server, M-x copilot-login)
;; サーバ未導入のときは copilot-mode がエラーになるので、導入済みのバッファだけ有効化する
(defun my/copilot-enable-if-installed ()
  "copilot-language-server が導入済みなら `copilot-mode' を有効にする。"
  (when (buffer-file-name)
    (require 'copilot)
    (when (ignore-errors (copilot-installed-version))
      (copilot-mode 1))))

(use-package copilot
  :hook (prog-mode . my/copilot-enable-if-installed)
  :bind (("C-c c" . copilot-complete)
         :map copilot-completion-map
         ("C-<tab>" . copilot-accept-completion)
         ("C-<return>" . copilot-accept-completion)
         ("M-f" . copilot-accept-completion-by-word)
         ("M-e" . copilot-accept-completion-by-line)
         ("M-n" . copilot-next-completion)
         ("M-p" . copilot-previous-completion))
  :custom
  (copilot-idle-delay 0.3)
  (copilot-indent-offset-warning-disable t)
  (copilot-max-char -1)
  :config
  (add-to-list 'copilot-indentation-alist '(emacs-lisp-mode 2))
  (add-to-list 'copilot-indentation-alist '(lisp-interaction-mode 2)))

;;; スペルチェック (brew install aspell が必要)
(use-package flyspell
  :ensure nil
  :if (executable-find "aspell")
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode))
  :custom
  (ispell-program-name "aspell")
  (ispell-extra-args '("--sug-mode=ultra" "--lang=en_US")))

(provide 'init-tools)
;;; init-tools.el ends here
