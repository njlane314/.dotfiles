;;; dotfiles-format.el --- Formatting helpers -*- lexical-binding: t; -*-

(defun dotfiles/clang-format-buffer ()
  "Format the current buffer with clang-format without risking its contents."
  (interactive)
  (unless (executable-find "clang-format")
    (user-error "clang-format executable not found"))
  (when (buffer-narrowed-p)
    (user-error "Widen the buffer before formatting"))
  (let ((source (current-buffer))
        (source-point (point))
        (filename (or buffer-file-name ""))
        (contents (buffer-string)))
    (with-temp-buffer
      (insert contents)
      (let* ((arguments
              (if (string= filename "")
                  nil
                (list (concat "--assume-filename=" filename))))
             (status
              (apply #'call-process-region
                     (point-min) (point-max)
                     "clang-format" t t nil arguments)))
        (unless (and (integerp status) (zerop status))
          (user-error "clang-format failed with status %s" status)))
      (let ((formatted (current-buffer)))
        (with-current-buffer source
          (atomic-change-group
            (replace-buffer-contents formatted))
          (goto-char (min source-point (point-max))))))))

(provide 'dotfiles-format)

;;; dotfiles-format.el ends here
