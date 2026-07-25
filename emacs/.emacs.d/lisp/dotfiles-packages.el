;;; dotfiles-packages.el --- Explicit package provisioning -*- lexical-binding: t; -*-

(defconst dotfiles/package-archives
  '(("gnu" . "https://elpa.gnu.org/packages/")
    ("nongnu" . "https://elpa.nongnu.org/nongnu/")
    ("melpa" . "https://melpa.org/packages/")))

(defconst dotfiles/package-archive-priorities
  '(("gnu" . 10)
    ("nongnu" . 5)
    ("melpa" . 0)))

(defconst dotfiles/packages
  '(vertico
    marginalia
    orderless
    consult
    corfu
    magit
    exec-path-from-shell
    markdown-mode
    yaml-mode
    json-mode))

(defun dotfiles/install-packages ()
  "Refresh package metadata and install missing dotfiles packages."
  (interactive)
  (require 'package)
  (setq package-archives dotfiles/package-archives
        package-archive-priorities dotfiles/package-archive-priorities)
  (package-initialize)
  (package-refresh-contents)
  (dolist (package dotfiles/packages)
    (unless (package-installed-p package)
      (package-install package t))))

(provide 'dotfiles-packages)

;;; dotfiles-packages.el ends here
