;;; early-init.el --- Early init -*- lexical-binding: t; -*-

;;; Commentary:
;; init.el より前に読まれる。GC・フレーム・キャッシュ先の設定だけを置く。

;;; Code:

;; 起動中は GC を抑え、起動後に元へ戻す
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; 生成物は ~/.cache/emacs に寄せ、~/.config/emacs は設定ファイルだけにする
(defconst my/cache-dir (expand-file-name "~/.cache/emacs/"))
(make-directory my/cache-dir t)
(setq package-user-dir (expand-file-name "elpa" my/cache-dir))
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache" my/cache-dir)))

;; native-comp の警告は静かに
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation t)

;; macOS 26 以降では同梱 GCC が clang に無効な -mmacosx-version-min を渡し、
;; トランポリン生成 (primitive への advice) が失敗するので明示する
(when (eq system-type 'darwin)
  (setq native-comp-driver-options '("-mmacosx-version-min=26.0")))

;; フレーム装飾は最初から外す
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(ns-transparent-titlebar . t) default-frame-alist)
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      use-dialog-box nil)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; package.el は init.el で初期化する
(setq package-enable-at-startup nil)

(provide 'early-init)
;;; early-init.el ends here
