;;; init-lang.el --- Language modes -*- lexical-binding: t; -*-

;;; Commentary:
;; Emacs 組込みの *-ts-mode を優先し、無い言語だけパッケージを足す。
;; モードの切替 (auto-mode-alist / major-mode-remap-alist) は treesit-auto が面倒を見る。

;;; Code:

;;; 組込み tree-sitter モードの設定
(use-package go-ts-mode
  :ensure nil
  :custom (go-ts-mode-indent-offset 4)
  :config
  (add-to-list 'auto-mode-alist '("go\\.mod\\'" . go-mod-ts-mode)))

(use-package rust-ts-mode
  :ensure nil
  :custom (rust-ts-mode-indent-offset 4))

(use-package typescript-ts-mode
  :ensure nil
  :custom (typescript-ts-mode-indent-offset 2)
  :mode (("\\.ts\\'" . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cts\\'" . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode)))

(use-package js
  :ensure nil
  :custom (js-indent-level 2)
  :mode (("\\.[cm]?js\\'" . js-ts-mode)
         ("\\.jsx\\'" . js-ts-mode)))

(use-package json-ts-mode
  :ensure nil
  :mode ("\\.json\\'" "\\.jsonc\\'" "\\.babelrc\\'"))

(use-package yaml-ts-mode
  :ensure nil
  :mode ("\\.ya?ml\\'"))

(use-package toml-ts-mode
  :ensure nil
  :mode ("\\.toml\\'" "Cargo\\.lock\\'"))

(use-package dockerfile-ts-mode
  :ensure nil
  :mode ("Dockerfile\\(?:\\..*\\)?\\'" "Containerfile\\'"))

(use-package lua-ts-mode
  :ensure nil
  :custom (lua-ts-indent-offset 2)
  :mode ("\\.lua\\'"))

(use-package ruby-ts-mode
  :ensure nil
  :mode ("\\.rb\\'" "\\.rake\\'" "Rakefile\\'" "Gemfile\\'" "\\.gemspec\\'"))

(use-package python
  :ensure nil
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3"))

(use-package sh-script
  :ensure nil
  :custom (sh-basic-offset 2)
  :mode (("\\.zsh\\'" . bash-ts-mode)
         ("\\.zshrc\\'" . bash-ts-mode)
         ("\\.zshenv\\'" . bash-ts-mode)))

(use-package cmake-ts-mode
  :ensure nil
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))

;;; パッケージが必要な言語
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode))
  :custom
  (markdown-fontify-code-blocks-natively t)
  (markdown-hide-urls nil)
  (markdown-command "pandoc")
  (markdown-header-scaling t)
  :hook (markdown-mode . visual-line-mode))

(use-package nix-ts-mode
  :mode "\\.nix\\'")

(use-package zig-mode
  :mode "\\.zig\\'"
  :custom (zig-format-on-save nil))

(use-package haskell-mode
  :mode "\\.hs\\'"
  :hook (haskell-mode . interactive-haskell-mode))

;; Emacs 31 向け tree-sitter モード。eglot の設定 (moon lsp) はパッケージ側が持つ
(use-package moonbit-ts-mode
  :vc (:url "https://github.com/moonbit-community/moonbit-ts-mode" :rev :newest)
  :mode ("\\.mbt\\(?:i\\|p\\)?\\'" "/moon\\.pkg\\'")
  :init
  (add-to-list 'treesit-language-source-alist
               '(moonbit "https://github.com/moonbitlang/tree-sitter-moonbit.git" "main" "src"))
  (add-to-list 'treesit-language-source-alist
               '(moonbit_mbtp "https://github.com/moonbitlang/tree-sitter-moonbit.git" "main" "grammars/mbtp/src"))
  :custom (moonbit-ts-indent-offset 2))

(use-package just-mode
  :mode ("justfile\\'" "\\.just\\'"))

(use-package web-mode
  :mode ("\\.html?\\'" "\\.vue\\'" "\\.svelte\\'" "\\.astro\\'")
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  (web-mode-enable-auto-pairing nil))

(use-package graphql-mode
  :mode "\\.graphqls?\\'")

(use-package protobuf-mode
  :mode "\\.proto\\'")

(use-package csv-mode
  :mode "\\.csv\\'")

(use-package git-modes
  :mode (("\\.gitignore\\'" . gitignore-mode)
         ("\\.gitconfig\\'" . gitconfig-mode)
         ("\\.gitattributes\\'" . gitattributes-mode)))

;;; org
(use-package org
  :ensure nil
  :custom
  (org-startup-indented t)
  (org-hide-emphasis-markers t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-directory "~/org")
  :hook (org-mode . visual-line-mode))

(provide 'init-lang)
;;; init-lang.el ends here
