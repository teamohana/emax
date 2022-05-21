;;; early-init.el --- Early Init File -*- lexical-binding: t; no-byte-compile: t -*-

;; --- defer GC to much later to speed up the startup process
(setq gc-cons-threshold most-positive-fixnum
      read-process-output-max 16777216
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            ;; restore after startup
            (setq gc-cons-threshold 16777216
                  gc-cons-percentage 0.1)))

;; --- redirect eln cache
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (convert-standard-filename
    (expand-file-name  ".local/var/eln-cache/" user-emacs-directory))))

;; --- reset package related settings
(setq package-enable-at-startup nil)
(setq package-quickstart nil)

;; --- basic settings for gui
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(height . 60) default-frame-alist)
(push '(width . 120) default-frame-alist)
(push '(left . 60) default-frame-alist)
(push '(top . 100) default-frame-alist)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; --- bunch of sane settings
(setq inhibit-splash-screen t
      use-file-dialog nil
      ring-bell-function #'ignore
      echo-keystrokes 1e-6
      comp-deferred-compilation nil
      native-comp-async-report-warnings-errors nil
      frame-inhibit-implied-resize t
      scroll-step 1
      scroll-conservatively 101
      scroll-preserve-screen-position 1
      mouse-wheel-scroll-amount '(1 ((shift) . 5))
      mouse-wheel-follow-mouse t
      scroll-margin 3
      truncate-lines nil
      frame-resize-pixelwise t
      initial-scratch-message nil
      frame-title-format "%b"
      inhibit-compacting-font-caches t)
