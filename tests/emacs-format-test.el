;;; emacs-format-test.el --- Tests for dotfiles-format -*- lexical-binding: t; -*-

(require 'dotfiles-format)

(let* ((fixtures (getenv "DOTFILES_TEST_FIXTURES"))
       (process-environment (copy-sequence process-environment))
       (dotfiles/llvm-exec-path (list fixtures)))
  (with-temp-buffer
    (setq buffer-file-name "/tmp/example file.cpp")
    (setenv "DOTFILES_EXPECTED_FILENAME" buffer-file-name)
    (insert "keep me\n")
    (setenv "DOTFILES_FORMATTER_RESULT" "failure")
    (condition-case nil
        (progn
          (dotfiles/clang-format-buffer)
          (error "A failed formatter did not signal an error"))
      (user-error nil))
    (unless (equal (buffer-string) "keep me\n")
      (error "A failed formatter changed the buffer"))
    (setenv "DOTFILES_FORMATTER_RESULT" "success")
    (goto-char 6)
    (dotfiles/clang-format-buffer)
    (unless (equal (buffer-string) "KEEP ME\n")
      (error "A successful formatter did not replace the buffer"))
    (unless (= (point) 6)
      (error "A successful formatter did not preserve the cursor")))
  (with-temp-buffer
    (setq buffer-file-name "/tmp/narrowed.cpp")
    (insert "before\nkeep me\nafter\n")
    (narrow-to-region 8 16)
    (condition-case nil
        (progn
          (dotfiles/clang-format-buffer)
          (error "Formatting a narrowed buffer did not signal an error"))
      (user-error nil))
    (widen)
    (unless (equal (buffer-string) "before\nkeep me\nafter\n")
      (error "Rejected narrowed formatting changed the full buffer"))))

;;; emacs-format-test.el ends here
