;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Package activation

(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

(require 'package)
(package-initialize)

(unless (require 'use-package nil t)
  (defmacro use-package (&rest _args)
    "Ignore package declarations when `use-package' is unavailable."
    nil))

;;; Files and paths

(defconst dotfiles/cache-dir (expand-file-name "var/" user-emacs-directory))
(defconst dotfiles/backup-dir (expand-file-name "backup/" dotfiles/cache-dir))
(defconst dotfiles/auto-save-dir (expand-file-name "auto-save/" dotfiles/cache-dir))

(dolist (dir (list dotfiles/backup-dir dotfiles/auto-save-dir))
  (make-directory dir t))

(setq backup-directory-alist `(("." . ,dotfiles/backup-dir))
      auto-save-file-name-transforms `((".*" ,dotfiles/auto-save-dir t))
      auto-save-list-file-prefix (expand-file-name ".saves-" dotfiles/auto-save-dir)
      save-place-file (expand-file-name "places" dotfiles/cache-dir)
      savehist-file (expand-file-name "history" dotfiles/cache-dir)
      recentf-save-file (expand-file-name "recentf" dotfiles/cache-dir)
      custom-file (expand-file-name "custom.el" dotfiles/cache-dir))

(when (file-readable-p custom-file)
  (load custom-file nil t))

(when (featurep 'use-package)
  (setq use-package-always-ensure nil
        use-package-expand-minimally t))

;;; Core editing defaults

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-dialog-box nil
      use-short-answers t
      require-final-newline t
      select-enable-clipboard t)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(delete-selection-mode 1)
(global-auto-revert-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(column-number-mode 1)
(global-hl-line-mode 1)
(when (require 'editorconfig nil t)
  (editorconfig-mode 1))

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none))

(ignore-errors
  (load-theme 'modus-vivendi t))

(dolist (hook '(prog-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))
(setq display-line-numbers-type 'relative)

;;; Key bindings

(global-set-key (kbd "C-c s") #'save-buffer)
(global-set-key (kbd "C-c k") #'kill-current-buffer)
(global-set-key (kbd "C-c e")
                (lambda ()
                  (interactive)
                  (find-file user-init-file)))

;;; Completion and navigation

(use-package vertico
  :if (locate-library "vertico")
  :init
  (vertico-mode 1))

(use-package marginalia
  :if (locate-library "marginalia")
  :init
  (marginalia-mode 1))

(use-package orderless
  :if (locate-library "orderless")
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package consult
  :if (locate-library "consult")
  :bind
  (("C-s" . consult-line)
   ("C-x b" . consult-buffer)
   ("M-y" . consult-yank-pop)
   ("C-c f" . consult-find)
   ("C-c r" . consult-ripgrep)))

(use-package corfu
  :if (locate-library "corfu")
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preview-current nil)
  :init
  (global-corfu-mode 1))

(use-package which-key
  :if (locate-library "which-key")
  :custom
  (which-key-idle-delay 0.35)
  :init
  (which-key-mode 1))

(use-package project
  :ensure nil
  :bind-keymap
  ("C-c p" . project-prefix-map)
  :custom
  (project-vc-extra-root-markers '(".project" "compile_commands.json")))

(use-package magit
  :if (locate-library "magit")
  :bind
  (("C-c g" . magit-status)))

(use-package exec-path-from-shell
  :if (and (memq window-system '(mac ns x))
           (locate-library "exec-path-from-shell"))
  :config
  (exec-path-from-shell-initialize))

;;; Programming

(add-to-list 'load-path (expand-file-name "lisp/" user-emacs-directory))
(require 'dotfiles-format)

(defconst dotfiles/clangd-program
  (dotfiles/llvm-executable "clangd"))

(use-package compile
  :ensure nil
  :custom
  (compilation-scroll-output 'first-error)
  :bind
  (("C-c m" . compile)
   ("C-c M" . recompile)))

(use-package flymake
  :ensure nil
  :bind
  (("M-n" . flymake-goto-next-error)
   ("M-p" . flymake-goto-prev-error)
   ("C-c !" . flymake-show-buffer-diagnostics)))

(defun dotfiles/c-c++-setup ()
  "Apply local defaults for C and C++ buffers."
  (setq-local c-basic-offset 4
              tab-width 4
              indent-tabs-mode nil)
  (when (boundp 'c-ts-mode-indent-offset)
    (setq-local c-ts-mode-indent-offset 4))
  (local-set-key (kbd "C-c C-f") #'dotfiles/clang-format-buffer))

(use-package cc-mode
  :ensure nil
  :hook
  ((c-mode-common c-ts-base-mode) . dotfiles/c-c++-setup))

(use-package eglot
  :if (and dotfiles/clangd-program (locate-library "eglot"))
  :bind
  (:map eglot-mode-map
        ("C-c R" . eglot-rename)
        ("C-c a" . eglot-code-actions))
  :hook
  ((c-mode c++-mode c-ts-mode c++-ts-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               `((c-mode c++-mode c-ts-mode c++-ts-mode)
                 . (,dotfiles/clangd-program
                    "--background-index" "--clang-tidy"
                    "--completion-style=detailed"))))

(use-package markdown-mode
  :if (locate-library "markdown-mode")
  :mode ("\\.md\\'" . markdown-mode))

(use-package yaml-mode
  :if (locate-library "yaml-mode")
  :mode "\\.ya?ml\\'")

(use-package json-mode
  :if (locate-library "json-mode")
  :mode "\\.json\\'")

;;; init.el ends here
