;;; makefile-runner.el --- Searches for Makefile and fetches targets

;; Copyright (C) 2009-2012 Dan Amlund Thomsen

;; Author: Dan Amlund Thomsen <dan@danamlund.dk>
;; URL: http://danamlund.dk/emacs/make-runner.html
;; Version: 1.0.1
;; Created: 2009-01-01
;; By: Dan Amlund Thomsen
;; Keywords: makefile, make

;;; Commentary:

;; An easy method of running Makefiles. The function searches current
;; and parent directories for a Makefile, fetches targets, and asks
;; the user which of the targets to run.

;; The function is `makefile-runner--make'.

;;; Installation:

;; Save makefile-runner.el to your load path and add the following to
;; your .emacs file:
;;
;; (require 'makefile-runner)

;; You can add a keybinding to run the function, for example:
;;
;; (global-set-key (kbd "F11") 'makefile-runner--make)

;;; Customization:

;; M-x customize-group makefile-runner
;;
;; You can change the regular expression that excludes targets by
;; changing `makefile-runner--target-exclusive-regexp'.
;;
;; And you can set a specific Makefile to use by changing
;; `makefile-runner--makefile'. A better method is to add a
;; file-variable to the affected files. For example, add to following
;; to the start of foo/src/foo.c:
;;
;; /* -*- makefile-runner--makefile: "../Makefile" -*- */

;;; Code:

;;;###autoload
(defcustom makefile-runner--makefile nil
  "Use this Makefile instead of searching for one. Intended to be
  used as a local variable (e.g. as a file variable: 
  -*- makefile-runner--makefile: \"../../Makefile\" -*-)"
  :type 'file
  :group 'makefile-runner)

;;;###autoload
(defcustom makefile-runner--target-exclusive-regexp "\\(^\\.\\)\\|[\\$\\%]"
  "Regular expression to exclude targets from the auto-complete list"
  :type 'regexp
  :group 'makefile-runner)

(defvar makefile-runner--last-target nil
  "Remembers the last target")

(defvar makefile-runner--hist nil
  "History of makefile targets")

(defun makefile-runner--find-makefile ()
  "Search current buffer's directory for a Makefile. If no
Makefile exists, continue searching in the directory's parent. If
no Makefile exists in any directory parents return nil."
  (when (buffer-file-name)
    (let ((path (file-name-directory (buffer-file-name)))
          (makefile-path ""))
      (while (and (>= (length path) 3)
                  (not (equal ".." (substring path -2)))
                  (not (file-exists-p (setq makefile-path
                                            (concat path "/Makefile")))))
        (setq path (expand-file-name ".." path)))
      (and (file-exists-p makefile-path)
           makefile-path))))

(defun makefile-runner--get-targets (file)
  "Search FILE for Makefile targets and return them as a list of
strings. Does not add targets that match the regular expression
in `makefile-runner--target-exclusive-regexp'."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-max))
    (let ((targets nil))
      (while (re-search-backward "^\\([^:\n#[:space:]]+?\\):" 
                                 (not 'bound) 'noerror)
        (unless (string-match makefile-runner--target-exclusive-regexp
                              (match-string 1))
          (setq targets (cons (match-string 1) targets))))
      targets)))

;;;###autoload
(defun makefile-runner--make (target &optional makefile)
  "Run nearest Makefile with TARGET.

When calling interactively. The targets from the nearest Makefile
is extracted and the user is asked which target to use.

Closest Makefile means first Makefile found when seacrching
upwards from the directory of the current buffer.

Set `makefile-runner--makefile' to use a specific Makefile rather
than search for one.

Change `makefile-runner--target-exclusive-regexp' to change which
targets are excluded."
  (interactive
   (let* ((makefile (or makefile-runner--makefile
                        (makefile-runner--find-makefile)))
          (makefile-dir (and makefile (file-name-directory makefile))))
     (if makefile
         (list (completing-read (format "%s make: " 
                                        (if (< (length makefile-dir) 40)
                                            makefile-dir
                                          (concat "..."
                                                  (substring makefile-dir -37))))
                                (makefile-runner--get-targets makefile)
                                nil nil makefile-runner--last-target
                                'makefile-runner--hist "")
               makefile)
       (progn (message "No makefile found.")
              (list nil nil)))))
  (when target
    (setq makefile-runner--last-target target)
    (compile (concat "cd " (file-name-directory makefile) "; "
                     "make " target "\n"))))

(provide 'makefile-runner)

;;; makefile-runner.el ends here
