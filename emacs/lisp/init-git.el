;;; init-git.el --- Git -*- lexical-binding: t; -*-

;;; Commentary:
;; magit を中心に、差分表示 (diff-hl)・履歴 (git-timemachine)・URL 共有 (git-link)。

;;; Code:

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c g" . magit-file-dispatch))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  (magit-revision-show-gravatars nil)
  (magit-log-margin '(t "%Y-%m-%d %H:%M" magit-log-margin-width t 18))
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  (git-commit-summary-max-length 72)
  :config
  (add-hook 'git-commit-setup-hook #'git-commit-turn-on-flyspell))

;; fringe に変更箇所を表示し、hunk 単位で stage / revert
(use-package diff-hl
  :hook ((after-init . global-diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :custom
  (diff-hl-draw-borders nil)
  (diff-hl-show-staged-changes nil)
  :config
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p)
    (diff-hl-margin-mode 1)))

;; ファイルの過去版を時系列で辿る
(use-package git-timemachine
  :bind ("C-c v t" . git-timemachine))

;; 現在行の GitHub URL をコピー / 開く
(use-package git-link
  :bind (("C-c v l" . git-link)
         ("C-c v c" . git-link-commit)
         ("C-c v h" . git-link-homepage))
  :custom (git-link-open-in-browser t))

;; コミットログを全文検索
(use-package consult-git-log-grep
  :bind ("C-c v g" . consult-git-log-grep)
  :custom (consult-git-log-grep-open-function #'magit-show-commit))

;; .git ディレクトリのあるパスから project.el へ登録
(use-package project
  :ensure nil
  :custom
  (project-vc-extra-root-markers '("moon.mod.json" "moon.work" "package.json" "Cargo.toml" "go.mod" "flake.nix"))
  (project-switch-commands '((project-find-file "Find file" ?f)
                             (consult-ripgrep "Grep" ?g)
                             (project-find-dir "Find dir" ?d)
                             (consult-project-buffer "Buffer" ?b)
                             (magit-project-status "Magit" ?m)
                             (project-eshell "Eshell" ?e)
                             (vterm-toggle-cd "Terminal" ?t))))

(provide 'init-git)
;;; init-git.el ends here
