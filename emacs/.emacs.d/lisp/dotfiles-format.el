;;; dotfiles-format.el --- Formatting helpers -*- lexical-binding: t; -*-

(defconst dotfiles/llvm-exec-path
  '("/opt/homebrew/opt/llvm/bin"
    "/usr/local/opt/llvm/bin"
    "/home/linuxbrew/.linuxbrew/opt/llvm/bin"))

(defun dotfiles/llvm-executable (program)
  "Return the preferred LLVM PROGRAM, falling back to `exec-path'."
  (locate-file program
               (append dotfiles/llvm-exec-path exec-path)
               exec-suffixes #'file-executable-p))

(defun dotfiles/clang-format-buffer ()
  "Format the current buffer with clang-format without risking its contents."
  (interactive)
  (when (buffer-narrowed-p)
    (user-error "Widen the buffer before formatting"))
  (let ((program (or (dotfiles/llvm-executable "clang-format")
                     (user-error "clang-format executable not found")))
        (source (current-buffer))
        (filename buffer-file-name)
        (cursor-offset (1- (position-bytes (point)))))
    (with-temp-buffer
      (insert-buffer-substring-no-properties source)
      (let* ((arguments
              (append
               (list (format "--cursor=%d" cursor-offset))
               (when filename
                 (list (concat "--assume-filename=" filename)))))
             (status
              (apply #'call-process-region
                     (point-min) (point-max)
                     program t t nil arguments)))
        (unless (and (integerp status) (zerop status))
          (user-error "clang-format failed with status %s" status)))
      (let ((formatted-cursor
             (save-match-data
               (goto-char (point-min))
               (unless (looking-at
                        "{.*\"Cursor\"[[:space:]]*:[[:space:]]*\\([0-9]+\\).*}")
                 (user-error "clang-format returned an invalid cursor response"))
               (string-to-number (match-string 1)))))
        (delete-region (point-min) (line-beginning-position 2))
        (let ((formatted (current-buffer))
              (formatted-point (byte-to-position (1+ formatted-cursor))))
          (unless formatted-point
            (user-error "clang-format returned an invalid cursor position"))
          (with-current-buffer source
            (atomic-change-group
              (replace-buffer-contents formatted))
            (goto-char formatted-point)))))))

(provide 'dotfiles-format)

;;; dotfiles-format.el ends here
