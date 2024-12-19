;;; po-ediff-previous-msgid.el --- ediff previous-msgid and msgid.
;;; Author: kuma35
;;; Created: 2024/12/18
;;; Commentary:
;; previous msgid is  '#|' marked in comment.
;;; Code:

(defcustom po-ediff-previous-msgid-buffer-a-name "*pepm-previous-msgid*"
  "'po-ediff-previous-msgid' BUFFER A name.  pepm is PoEdiffPreviousMsgid."
  :type 'string
  :require 'po-mode
  :group 'po)

(defcustom po-ediff-previous-msgid-buffer-b-name "*pepm-now-msgid*"
  "'po-ediff-previous-msgid' BUFFER A name.  pepm is PoEdiffPreviousMsgid."
  :type 'string
  :require 'po-mode
  :group 'po)


(defun po-extract-previous-msgid (buffer start end)
  "Delete '#|' marker and unquote text from BUFFER START END.
delete '^#| ' each line.  then unquote.
return is String with property."
  (with-temp-buffer
    (insert-buffer-substring buffer start end)
    (goto-char (point-min))
    (while (re-search-forward "^#\\(~\\)?|[ \t]*" nil t)
      (replace-match "" t t))
    (po-extract-unquoted (current-buffer) (point-min) (point-max))
    )
  )

(defun po-ediff-previous-msgid ()
  "Ediff previous msgid (marked #| ) and msgid."
  (interactive)
  (require 'po-mode)
  (po-find-span-of-entry)
  (let (
	(oldbuf (current-buffer))
	(msgid (po-get-msgid))
	(untranslated-regions (po-previous-untranslated-regions))
        (beg-A)
	(end-A)
	(beg-B)
	(end-B)
	)
    ;; source buffer for buffer-A
    (save-current-buffer
      (set-buffer (get-buffer-create
		   po-ediff-previous-msgid-buffer-a-name))
      (setq buffer-read-only nil)
      (erase-buffer)
      (dolist (region untranslated-regions)
	(insert (po-extract-previous-msgid oldbuf (car region) (cdr region)))
	)
      (setq beg-A (point-min))
      (setq end-A (point-max))
      (goto-char (point-min))
      (push-mark (point-max) t t)
      (setq buffer-read-only t)
      (restore-buffer-modified-p nil))
    ;; source buffer for buffer-B
    (save-current-buffer
      (set-buffer (get-buffer-create
		   po-ediff-previous-msgid-buffer-b-name))
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert msgid)
      (setq beg-B (point-min))
      (setq end-B (point-max))
      (goto-char (point-min))
      (push-mark (point-max) t t)
      (setq buffer-read-only t)
      (restore-buffer-modified-p nil))
    ;; run ediff
    (ediff-regions-internal
     (get-buffer po-ediff-previous-msgid-buffer-a-name)
     beg-A end-A
     (get-buffer po-ediff-previous-msgid-buffer-b-name)
     beg-B end-B
     nil 'ediff-regions-wordwise 'word-mode nil)
    )  ; end of let
  )

(provide 'po-ediff-previous-msgid)
;;; po-ediff-previous-msgid.el ends here
