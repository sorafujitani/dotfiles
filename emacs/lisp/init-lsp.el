;;; init-lsp.el --- LSP, tree-sitter, formatting, diagnostics -*- lexical-binding: t; -*-

;;; Commentary:
;; LSP は組込みの eglot。サーバは nix / brew / mise で導入済みのものを使う。
;; 構文解析は組込み tree-sitter。grammar は初回に自動で取得する。
;; フォーマットは apheleia、診断は flymake、デバッグは dape。

;;; Code:

;;; tree-sitter (Emacs 31 の組込み機能だけで完結させる)
(use-package treesit
  :ensure nil
  :custom
  (treesit-font-lock-level 4)
  ;; grammar が無ければ確認なしで取得・ビルドする
  (treesit-auto-install-grammar 'always)
  ;; 組込みの *-ts-mode をすべて既定にする (major-mode-remap-defaults)
  (treesit-enabled-modes t)
  :config
  ;; grammar の置き場所 (treesit-extra-load-path の先頭が書込み先になる)
  (let ((dir (expand-file-name "tree-sitter" my/cache-dir)))
    (make-directory dir t)
    (add-to-list 'treesit-extra-load-path dir)))

;; 構文木に沿ってリージョンを広げる (C-= で段階的に拡張)
(use-package expreg
  :bind (("C-=" . expreg-expand)
         ("C-+" . expreg-contract)))

;;; eglot
(use-package eglot
  :ensure nil
  :hook ((go-ts-mode go-mod-ts-mode
          rust-ts-mode
          typescript-ts-mode tsx-ts-mode js-ts-mode
          lua-ts-mode lua-mode
          ruby-ts-mode ruby-mode
          python-ts-mode python-mode
          nix-ts-mode nix-mode
          zig-mode zig-ts-mode
          haskell-mode haskell-ts-mode
          markdown-mode markdown-ts-mode
          json-ts-mode yaml-ts-mode
          bash-ts-mode sh-mode
          c-ts-mode c++-ts-mode)
         . eglot-ensure)
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l o" . eglot-code-action-organize-imports)
              ("C-c l f" . eglot-format-buffer)
              ("C-c l d" . eglot-find-declaration)
              ("C-c l i" . eglot-find-implementation)
              ("C-c l t" . eglot-find-typeDefinition)
              ("C-c l s" . consult-eglot-symbols)
              ("C-c l h" . eldoc-box-help-at-point)
              ("C-c l R" . eglot-reconnect)
              ("C-c l q" . eglot-shutdown))
  :custom
  (eglot-autoshutdown t)
  (eglot-sync-connect 1)
  (eglot-connect-timeout 30)
  (eglot-send-changes-idle-time 0.3)
  (eglot-extend-to-xref t)
  (eglot-events-buffer-config '(:size 0 :format full))
  (eglot-report-progress nil)
  (eglot-ignored-server-capabilities '(:inlayHintProvider))
  :config
  (dolist (entry
           '(((lua-ts-mode lua-mode) . ("lua-language-server"))
             ((ruby-ts-mode ruby-mode) . ("ruby-lsp"))
             ((python-ts-mode python-mode) . ("ty" "server"))
             ((nix-ts-mode nix-mode) . ("nil"))
             ((zig-mode zig-ts-mode) . ("zls"))
             ((markdown-mode markdown-ts-mode) . ("marksman" "server"))))
    (add-to-list 'eglot-server-programs entry))
  (setq-default eglot-workspace-configuration
                '(:gopls (:usePlaceholders t
                          :staticcheck t
                          :gofumpt t)
                  :rust-analyzer (:check (:command "clippy")
                                  :cargo (:allFeatures t)))))

;; ワークスペースシンボル検索
(use-package consult-eglot
  :after (consult eglot))

;; eldoc を子フレームで表示
(use-package eldoc-box
  :after eglot
  :custom
  (eldoc-box-max-pixel-width 900)
  (eldoc-box-max-pixel-height 600)
  (eldoc-box-clear-with-C-g t))

(setq eldoc-echo-area-use-multiline-p nil
      eldoc-echo-area-prefer-doc-buffer t
      eldoc-idle-delay 0.3)

;;; 診断 (eglot が flymake を有効化する)
(use-package flymake
  :ensure nil
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error)
              ("C-c ! l" . flymake-show-buffer-diagnostics)
              ("C-c ! p" . flymake-show-project-diagnostics))
  :custom
  (flymake-no-changes-timeout 0.5)
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-show-diagnostics-at-end-of-line 'short)
  (flymake-indicator-type 'margins))

;;; フォーマット (保存時に自動整形)
(use-package apheleia
  :hook (after-init . apheleia-global-mode)
  :bind ("C-c f" . apheleia-format-buffer)
  :config
  (setf (alist-get 'gofumpt apheleia-formatters) '("gofumpt"))
  (setf (alist-get 'biome apheleia-formatters)
        '("biome" "format" "--stdin-file-path" filepath))
  (setf (alist-get 'stylua apheleia-formatters)
        '("stylua" "--search-parent-directories" "--stdin-filepath" filepath "-"))
  (setf (alist-get 'moon-fmt apheleia-formatters) '("moon" "fmt" "--stdin"))
  (dolist (pair '((go-ts-mode . gofumpt)
                  (go-mode . gofumpt)
                  (typescript-ts-mode . biome)
                  (tsx-ts-mode . biome)
                  (js-ts-mode . biome)
                  (json-ts-mode . biome)
                  (lua-ts-mode . stylua)
                  (lua-mode . stylua)
                  (nix-ts-mode . nixfmt)
                  (nix-mode . nixfmt)
                  (rust-ts-mode . rustfmt)
                  (ruby-ts-mode . rubocop)
                  (python-ts-mode . ruff)
                  (zig-mode . zig-fmt)))
    (setf (alist-get (car pair) apheleia-mode-alist) (cdr pair)))
  (setq apheleia-remote-algorithm 'local
        apheleia-log-only-errors t))

;;; デバッガ (DAP)
;; キーは gud と同じ C-x C-a prefix (dape-key-prefix)
(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  (dape-cwd-function #'my/project-root-or-default)
  :config
  (dape-breakpoint-global-mode 1)
  (add-hook 'dape-compile-hook #'kill-buffer)
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t))))

(defun my/project-root-or-default ()
  "プロジェクトルート、なければ `default-directory'。"
  (if-let* ((proj (project-current)))
      (project-root proj)
    default-directory))

(provide 'init-lsp)
;;; init-lsp.el ends here
