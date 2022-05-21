;;; init.el --- Early Init File -*- lexical-binding: t; no-byte-compile: t -*-

;; ----------------------
;; --- top-level settings
;; ----------------------
(setq emax--local-dir (expand-file-name ".local/" user-emacs-directory))
(setq emax--save-dir (expand-file-name "save/" emax--local-dir))

;; change these to your liking
(setq emax--default-font "Monaco")
(setq emax--variable-pitch-font "Gill Sans")
(setq emax--default-font-size 150)

(setq emax--fixed-pitch-font emax--default-font)
(setq emax--default-font-weight 'regular)


;; ------------------------------------
;; --- kill buffer without confirmation
;; ------------------------------------
(defun emax/kill-current-buffer ()
  "Kill the current buffer, without confirmation."
  (interactive)
  (kill-buffer (current-buffer)))

(global-set-key "\C-xk" 'emax/kill-current-buffer)


;; --------------------------------------
;; --- setup straight.el for package mgmt
;; --------------------------------------
(setf straight-base-dir (expand-file-name "var/" emax--local-dir))
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" straight-base-dir))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)  ; use-package is for config mgmt

;; -------------------------------------------
;; Hack the Emacs GC for better responsiveness
;; -------------------------------------------
(use-package gcmh
  :straight t
  :demand t
  :config
  (gcmh-mode 1))

;; -----------------------------
;; --- show startup time on load
;; -----------------------------
(defun emax/display-startup-time ()
  "Calculate Emacs startup time."
  (message
   "GNU/Emacs (v%s) ready in %s secs (%d GCs)"
   emacs-version
   (format
    "%.3f"
    (float-time
     (time-subtract after-init-time before-init-time)))
   gcs-done))

(add-hook 'emacs-startup-hook #'emax/display-startup-time)


;; ------------------
;; --- MacOS settings
;; ------------------
(when (equal system-type 'darwin)
  (setq mac-option-modifier 'super
        mac-command-modifier 'meta)

  ;; (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (add-to-list 'default-frame-alist '(ns-appearance . dark))

  (set-fontset-font t 'symbol (font-spec :family "Apple Symbols") nil 'prepend)
  (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend))

; we need this to set PATH etc correctly
(use-package exec-path-from-shell
  :straight t
  :init (exec-path-from-shell-initialize))


;; ------------------------
;; --- more sanity settings
;; ------------------------
(use-package emacs
  :init
  (setq tab-width 4
        tab-always-indent 'complete
        require-final-newline t
        truncate-string-ellipsis "…"
        custom-safe-themes t
        sentence-end-double-space nil
        confirm-kill-emacs #'yes-or-no-p
        completion-cycle-threshold 3)
  (setq-default indent-tabs-mode nil
                fill-column 115)

  (progn
    (delete-selection-mode t)
    (column-number-mode t)
    (size-indication-mode t)
    (prefer-coding-system 'utf-8)
    (set-charset-priority 'unicode)
    (set-default-coding-systems 'utf-8)
    (set-terminal-coding-system 'utf-8)
    (set-keyboard-coding-system 'utf-8)
    (add-hook 'before-save-hook #'delete-trailing-whitespace)
    (defalias 'yes-or-no-p 'y-or-n-p)
    (add-hook 'prog-mode-hook #'display-line-numbers-mode))

  (with-eval-after-load "use-package-core"
    (add-to-list 'use-package-keywords ':display)
    (defun use-package-normalize/:display (_name-symbol _keyword args)
      args)

    (defun use-package-handler/:display (name _keyword args rest state)
      (use-package-concat
       (use-package-process-keywords name rest state)
       (let ((arg args)
             forms)
         (while arg
           (add-to-list 'forms
                        `(add-to-list 'display-buffer-alist
                                      ',(car arg)))
           (setq arg (cdr arg)))
         forms))))
  :bind
  ("C-c C-w" . #'world-clock)
  :custom
  (world-clock-list
   '(("Asia/Calcutta" "Pune")
     ("America/Los_Angeles" "San Francisco")
     ("America/New_York" "New York")
     ("Etc/UTC" "UTC"))
   (world-clock-time-format "%a, %d %b %I:%M %p %Z")))


;; -----------------------
;; --- Keep .emacs.d clean
;; -----------------------
(use-package no-littering
  :straight t
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "config/"  emax--save-dir)
        no-littering-var-directory (expand-file-name "data/" emax--save-dir))
  :config
  (eval-after-load "recentf"
    '(progn
       (add-to-list 'recentf-exclude no-littering-var-directory)
       (add-to-list 'recentf-exclude no-littering-etc-directory)))
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))


;; ----------------------
;; --- some core packages
;; ----------------------
(use-package recentf ; to remember recent files
  :straight nil
  :init
  (recentf-mode 1)
  :config
  (setq recentf-max-saved-items 500
        recentf-max-menu-items 15
        recentf-auto-cleanup 'never))

(use-package super-save ; save files when we can
  :straight t
  :init
  (super-save-mode 1)
  :config
  (setq super-save-auto-save-when-idle t)
  (setq auto-save-default nil))

(use-package saveplace ; save cursor position
  :straight t
  :init
  (save-place-mode 1)
  :config
  (setq save-place-file
        (expand-file-name "saveplace" emax--save-dir))
  (setq-default save-place t))

(use-package savehist ; minibuffer history
  :straight t
  :init
  (savehist-mode 1)
  :config
  (setq savehist-additional-variables '(search-ring regexp-search-ring)
        savehist-autosave-interval 60
        savehist-file (expand-file-name "savehist" emax--save-dir)))

(use-package uniquify ; uniquify buffer names
  :straight nil
  :custom (uniquify-buffer-name-style 'forward))

(use-package undo-fu ; make undo work as usual
  :straight t
  :bind (("M-z" . undo-fu-only-undo)    ;MacOS keybindings
         ("S-M-z" . undo-fu-only-redo))
  :init
  (global-unset-key (kbd "M-z")))


;; -----------------------------------------
;; --- important packages for core behaviour
;; -----------------------------------------
(use-package blackout ; clean mode-lines
  :straight t
  :demand t
  :config
  (blackout 'super-save-mode)
  (blackout 'auto-fill-mode)
  (blackout 'eldoc-mode)
  (blackout 'whitespace-mode)
  (blackout 'emacs-lisp-mode "EL"))

(use-package selectrum ; for file opening, etc
  :straight t
  :defer t
  :bind
  (("C-M-r" . selectrum-repeat)
   :map selectrum-minibuffer-map
   ("C-r" . selectrum-select-from-history)
   :map minibuffer-local-map
   ("M-h" . backward-kill-word))
  :custom
  (selectrum-fix-minibuffer-height t)
  (selectrum-num-candidates-displayed 8)
  :custom-face
  ;; (selectrum-current-candidate ((t (:background "#D8DEE9" :foreground "#3B4252"))))
  :init
  (selectrum-mode +1)
  :config
  (global-set-key (kbd "C-x C-z") #'selectrum-repeat))

(use-package prescient ; for better sorting
  :straight t
  :config
  (prescient-persist-mode +1)
  (setq prescient-history-length 1000))

(use-package selectrum-prescient
  :straight t
  :demand t
  :after (selectrum prescient)
  :init
  (selectrum-prescient-mode +1)
  (prescient-persist-mode +1)
  :custom
  (prescient-filter-method '(literal regexp initialism)))

(use-package marginalia ; better minibuffer info
  :after selectrum
  :straight t
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode)
  (setq marginalia-annotators '(marginalia-annotators-heavy
                                marginalia-annotators-light
                                nil)))

(use-package ctrlf ; better buffer search
  :straight t
  :bind (("C-s" . ctrlf-forward-default)
         ("C-M-s" . ctrlf-forward-alternate)
         ("C-r" . ctrlf-backward-default)
         ("C-M-r" . ctrlf-backward-alternate))
  :config (ctrlf-mode +1))

(use-package corfu ; nice completion ui
  :straight (:type git
                   :host github
                   :repo "minad/corfu"
                   :branch "main"
                   :files (:defaults "extensions/*.el"))
  :ensure t
  :defer t
  :hook ((prog-mode . corfu-mode)
         (corfu-mode . corfu-history-mode))
  :bind (:map corfu-map
              ("C-q" . #'corfu-quick-insert)
              ("C-g" . #'corfu-quit)
              ("<return>" . #'corfu-insert))
  :custom
  (corfu-cycle nil)
  (corfu-auto t)
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match t)
  (corfu-scroll-margin 5)
  :custom-face
  ;; (corfu-current ((t (:background "wheat1" :foreground "blue4"))))
  ;; (corfu-border ((t (:background "wheat1"))))
  )

(use-package corfu-doc ; show docs while completing
  :straight t
  :after corfu
  :custom
  (corfu-doc-auto nil)
  (corfu-doc-max-width 85)
  (corfu-doc-max-height 20)
  :bind (:map corfu-map
              ("M-d" . #'corfu-doc-toggle)
              ("M-p" . #'corfu-doc-scroll-down)
              ("M-n" . #'corfu-doc-scroll-up))
  :hook (corfu-mode . corfu-doc-mode))

(use-package kind-icon ; nice icons in completion
  :straight t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package orderless ; ordering of completion suggestions
  :straight t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package multiple-cursors ; multiple cursors
  :defer t
  :straight t
  :bind
  (("C-M-s-. C-M-s-." . mc/edit-lines)
   ("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-c C-<" . mc/mark-all-like-this)))

(use-package helpful ; better help system
  :straight t
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key)
  :display
  ("\\*[Hh]elp.*"
   (display-buffer-at-bottom)
   (inhibit-duplicate-buffer . t)
   (window-height . 0.33)))


;; -------------------
;; --- developer stuff
;; -------------------
(use-package magit ; best ui for git
  :straight t
  :defer t
  :init
  (setq git-commit-fill-column 72)
  (setq magit-log-arguments '("--graph" "--decorate" "--color"))
  (setq magit-diff-refine-hunk t))

(use-package diff-hl ; highlight diffs
  :straight t
  :after magit
  :hook
  ((magit-pre-refresh . diff-hl-magit-pre-refresh)
   (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  (setq diff-hl-draw-borders nil)
  :config
  (global-diff-hl-mode))

(use-package rainbow-delimiters ; nice looking delimiters
  :defer t
  :straight t
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)))

(use-package flycheck ; on the fly quality checks
  :straight t
  :blackout t
  :config
  (setq-default flycheck-indication-mode 'left-fringe)
  (setq-default flycheck-highlighting-mode 'symbols)
  :hook
  ((prog-mode . flycheck-mode)
   (flycheck-mode . flycheck-set-indication-mode)))

(use-package whitespace ; visualize whitespace
  :straight t
  :blackout t
  :commands (whitespace-mode)
  :hook ((prog-mode . whitespace-mode)
         (text-mode . whitespace-mode)
         (before-save . whitespace-cleanup))
  :config
  (setq whitespace-line-column 115)
  (setq whitespace-style '(face tabs empty trailing lines-tail)))

(use-package smartparens ; better structural editing
  :straight t
  :blackout t
  :defer t
  :hook ((prog-mode . smartparens-mode))
  :bind
  (:map smartparens-mode-map
        ("M-(" . #'sp-wrap-round)
        ("M-{" . #'sp-wrap-curly)
        ("M-[" . #'sp-wrap-square))
  :config
  (progn
    (setq sp-base-key-bindings 'paredit)
    (setq sp-autoskip-closing-pair 'always)
    (setq sp-hybrid-kill-entire-symbol nil)
    (sp-use-paredit-bindings)
    (sp-pair "'" nil :unless '(sp-point-after-word-p))
    (sp-local-pair 'emacs-lisp-mode "`" "'")
    (sp-local-pair 'emacs-lisp-mode "'" nil :actions nil)
    (sp-local-pair 'clojure-mode "'" nil :actions nil)
    (sp-local-pair 'cider-mode "'" nil :actions nil)
    (sp-local-pair 'cider-repl-mode "'" nil :actions nil)))

(use-package hl-todo
  :straight t
  :defer t
  :init
  (global-hl-todo-mode 1)
  :custom
  (hl-todo-keyword-faces '(("TODO"   . "#BF616A")
                           ("FIXME"  . "#EBCB8B")
                           ("DEBUG"  . "#B48EAD")
                           ("GOTCHA" . "#D08770")
                           ("XXX"   . "#81A1C1"))))


;; -----------
;; --- clojure
;; -----------
(use-package clojure-mode
  :straight t
  :blackout ((clojure-mode . "CLJ")
             (clojurec-mode . "CLJC")
             (clojurescript-mode . "CLJS"))
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.cljc\\'" . clojurec-mode)
         ("\\.cljs\\'" . clojurescript-mode)
         ("\\.edn\\'" . clojure-mode))
  :hook ((clojure-mode . subword-mode)
         (clojure-mode . smartparens-mode)
         (clojure-mode . rainbow-delimiters-mode)
         (clojure-mode . eldoc-mode))
  :config
  (setq clojure-indent-style 'always-indent))

(use-package cider
  :straight t
  :after clojure-mode
  :blackout t
  :bind
  (("C-c C-l" . cider-repl-clear-buffer))
  :config
  (setq nrepl-log-messages t
        cider-repl-display-in-current-window t
        cider-repl-pop-to-buffer-on-connect nil
        cider-repl-use-clojure-font-lock t
        cider-repl-use-content-types t
        cider-save-file-on-load t
        cider-prompt-for-symbol nil
        cider-font-lock-dynamically '(macro core var)
        nrepl-hide-special-buffers t
        cider-repl-buffer-size-limit 100000
        cider-overlays-use-font-lock t
        cider-dynamic-indentation nil
        cider-repl-display-help-banner nil
        cider-repl-prompt-function #'cider-repl-prompt-abbreviated
        cider-format-code-options '(("indents" ((".*" (("inner" 0)))))))
  (cider-repl-toggle-pretty-printing)
  :hook
  (cider-repl-mode . smartparens-mode))

(use-package flycheck-clj-kondo
  :straight t)


;; --------------------
;; --- themes and fonts
;; --------------------
(set-face-attribute 'default nil
                    :family emax--default-font
                    :height emax--default-font-size
                    :weight emax--default-font-weight)

(set-face-attribute 'fixed-pitch nil
                    :font emax--fixed-pitch-font)

(set-face-attribute 'variable-pitch nil
                    :font emax--variable-pitch-font)

(use-package doom-themes
  :straight t
  :config
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-wilmersdorf t)

  (doom-themes-visual-bell-config)
  ;; (setq doom-themes-treemacs-theme "doom-atom")
  ;; (doom-themes-treemacs-config)
  (doom-themes-org-config))

(use-package mood-line
  :straight t
  :demand t
  :init
  (mood-line-mode))

(use-package all-the-icons
  :straight t
  :if (display-graphic-p))

(use-package all-the-icons-completion
  :straight t
  :after all-the-icons
  :hook
  (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))

(use-package all-the-icons-dired
  :straight t
  :after all-the-icons
  :hook
  (dired-mode . all-the-icons-dired-mode))
