;;; init-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:
;; ミニバッファ: vertico + orderless + marginalia + consult + embark
;; バッファ内:   corfu + cape + yasnippet
;; 標準の completing-read / completion-at-point をそのまま使い、UI だけ差し替える。

;;; Code:

;;; ミニバッファ
(use-package vertico
  :hook (after-init . vertico-mode)
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  (vertico-resize nil)
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :config
  (require 'vertico-directory)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion))
                                   (eglot (styles orderless))
                                   (eglot-capf (styles orderless))))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex)))

(use-package marginalia
  :hook (after-init . marginalia-mode)
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle)))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; consult のキーは公式 README の推奨配置に従う
(use-package consult
  :bind (;; C-c
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x
         ("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ;; register
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ;; yank
         ("M-y" . consult-yank-pop)
         ;; M-g goto
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s search
         ("M-s d" . consult-fd)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-ripgrep)
         ("M-s G" . consult-git-grep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :custom
  (consult-narrow-key "<")
  (consult-preview-key '(:debounce 0.2 any))
  (consult-async-min-input 2)
  (consult-async-refresh-delay 0.15)
  (consult-fd-args '("fd" "--full-path" "--color=never" "--hidden" "--exclude" ".git"))
  (consult-ripgrep-args
   "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --hidden --glob !.git")
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  (register-preview-delay 0.5)
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  :config
  ;; 重い候補はプレビューを手動 (M-.) に
  (consult-customize
   consult-theme consult-recent-file consult-buffer consult-ripgrep consult-fd consult-git-grep
   consult-bookmark consult-xref
   :preview-key "M-."))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings)
         :map minibuffer-local-map
         ("C-c C-e" . embark-export)
         ("C-c C-c" . embark-collect))
  :custom
  (prefix-help-command #'embark-prefix-help-command)
  (embark-indicators '(embark-minimal-indicator embark-highlight-indicator embark-isearch-highlight-indicator)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; embark-export した grep 結果をその場で編集して一括置換
(use-package wgrep
  :custom (wgrep-auto-save-buffer t))

;;; バッファ内補完
(setq tab-always-indent 'complete
      text-mode-ispell-word-completion nil
      read-extended-command-predicate #'command-completion-default-include-p
      completion-ignore-case t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t)

(use-package corfu
  :hook (after-init . global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-min-width 24)
  (corfu-max-width 100)
  :bind (:map corfu-map
              ("M-SPC" . corfu-insert-separator)
              ("RET" . nil)
              ("M-d" . corfu-popupinfo-toggle))
  :config
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1)
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package nerd-icons-corfu
  :after corfu
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-keyword)
  :custom (cape-dabbrev-min-length 3))

;;; スニペット
(use-package yasnippet
  :hook (after-init . yas-global-mode)
  :custom
  (yas-snippet-dirs (list (expand-file-name "snippets" user-emacs-directory)))
  (yas-verbosity 1))

(use-package yasnippet-snippets
  :after yasnippet
  :config (yasnippet-snippets-initialize))

(use-package yasnippet-capf
  :after (cape yasnippet)
  :init (add-hook 'completion-at-point-functions #'yasnippet-capf))

;; eglot の補完に cape を合成して、LSP + スニペット + ファイル名を同時に出す
(defun my/eglot-capf ()
  "eglot バッファの completion-at-point-functions を合成する。"
  (setq-local completion-at-point-functions
              (list (cape-capf-super #'eglot-completion-at-point #'yasnippet-capf)
                    #'cape-file
                    #'cape-dabbrev)))
(add-hook 'eglot-managed-mode-hook #'my/eglot-capf)

(provide 'init-completion)
;;; init-completion.el ends here
