;;; init-keys.el --- User keys under C-c -*- lexical-binding: t; -*-

;;; Commentary:
;; 標準キーは変えない。ユーザー予約の C-c <letter> と各モードの慣例 prefix だけ使う。
;; 各パッケージの :bind はそのモジュール側にあり、ここは小さな補助コマンドと which-key の見出し。
;;
;;   C-c c   copilot-complete        C-c o   dirvish-side
;;   C-c f   apheleia-format-buffer  C-c t   vterm-toggle
;;   C-c g   magit-file-dispatch     C-c z   olivetti-mode
;;   C-c l   eglot                   C-c v   git (timemachine / link / log grep)
;;   C-c p   cape                    C-c s   puni
;;   C-c !   flymake                 C-c y   path をコピー
;;   C-c e   設定ファイルを開く       C-c r   設定を再読込
;;   C-x g   magit-status            C-x u   vundo
;;   C-x C-a dape                    M-o     ace-window
;;   M-s     consult 検索            M-g     consult 移動 / avy
;;   C-.     embark-act              C-=     expreg-expand

;;; Code:

(defun my/copy-file-path ()
  "現在ファイルのプロジェクト相対パスを kill-ring に入れる。"
  (interactive)
  (if-let* ((file (buffer-file-name)))
      (let ((path (if-let* ((proj (project-current)))
                      (file-relative-name file (project-root proj))
                    (abbreviate-file-name file))))
        (kill-new path)
        (message "Copied: %s" path))
    (user-error "Buffer is not visiting a file")))

(defun my/open-emacs-config ()
  "Emacs 設定ディレクトリ内のファイルを選んで開く。"
  (interactive)
  (let ((default-directory user-emacs-directory))
    (call-interactively #'project-find-file)))

(defun my/reload-init ()
  "init.el を読み直す。"
  (interactive)
  (load-file user-init-file))

(keymap-global-set "C-c y" #'my/copy-file-path)
(keymap-global-set "C-c e" #'my/open-emacs-config)
(keymap-global-set "C-c r" #'my/reload-init)

;; 行の移動・複製 (標準に無い最小限)
(use-package move-text
  :bind (("M-<up>" . move-text-up)
         ("M-<down>" . move-text-down)))
(keymap-global-set "C-c D" #'duplicate-dwim)

;; which-key の prefix 見出し
(which-key-add-key-based-replacements
  "C-c l" "eglot"
  "C-c v" "git"
  "C-c s" "puni"
  "C-c p" "cape"
  "C-c !" "flymake"
  "C-x C-a" "dape"
  "M-s" "search"
  "M-g" "goto")

(provide 'init-keys)
;;; init-keys.el ends here
