;;; po-ediff-previous-msgid.el --- ediff previous-msgid & msgid.
;;; Author: kuma35
;;; Created: 2024/12/18
;;; Commentary:
;; In po-mode,
;; previous msgid is  '#|' marked in comment.
;; msgid is soruce sentence.
;; (msgstr is translated sentence.)
;; PEPM is my generate word.  PoEdiffPreviousMsgid.
;; Ediff-ing previous-msgid and msgid.
;;; Code:

(declare-function
 po-extract-unquoted "po-mode" (buffer start end))
(declare-function po-find-span-of-entry "po-mode" ())
(declare-function po-get-msgid "po-mode" ())
(declare-function po-previous-untranslated-regions "po-mode" ())
(declare-function
 ediff-regions-internal "ediff"
 (buffer-A beg-A end-A buffer-B beg-B end-B
	   startup-hooks job-name word-mode setup-parameters))

(defcustom po-pepm-buf-a-name "*pepm-previous-msgid*"
  "BUFFER A name for `po-ediff-previous-msgid`.
PEPM is PoEdiffPreviousMsgid."
  :type 'string
  :require 'po-mode
  :group 'po)

(defcustom po-pepm-buf-b-name "*pepm-now-msgid*"
  "BUFFER B name for `po-ediff-previous-msgid` .
PEPM is PoEdiffPreviousMsgid."
  :type 'string
  :require 'po-mode
  :group 'po)


(defun po-extract-previous-msgid (buffer start end)
  "Delete '#|' marker and unquote text from BUFFER START END.
delete '^#| ' each line.  then unquote.
return is String with property."
  (require 'po-mode)
  (with-temp-buffer
    (insert-buffer-substring buffer start end)
    (goto-char (point-min))
    (while (re-search-forward "^#\\(~\\)?|[ \t]*" nil t)
      (replace-match "" t t))
    (po-extract-unquoted
     (current-buffer) (point-min) (point-max))
    )
  )

(defun po-ediff-previous-msgid ()
  "Ediff previous msgid (marked #| ) and msgid."
  (interactive)
  (require 'po-mode)
  (require 'ediff)
  (po-find-span-of-entry)
  (let (
	(oldbuf (current-buffer))
	(msgid (po-get-msgid))
	(untranslated-regions
	 (po-previous-untranslated-regions))
        (beg-A) (end-A)  ; BUF-A for ediff-regions-internal
	(beg-B) (end-B)  ; BUF-B for ediff-regions-internal
	)
    ;; nothing previous msgid then exit
    (if (not untranslated-regions)
	(error "Nothing previous msgid."))
    ;; source buffer for buffer-A
    (save-current-buffer
      (set-buffer (get-buffer-create
		   po-pepm-buf-a-name))
      (setq buffer-read-only nil)
      (erase-buffer)
      (dolist (region untranslated-regions)
	(insert (po-extract-previous-msgid
		 oldbuf (car region) (cdr region)))
	)
      (goto-char (setq beg-A (point-min)))
      (push-mark (setq end-A (point-max)) t t)
      (setq buffer-read-only t)
      (restore-buffer-modified-p nil))
    ;; source buffer for buffer-B
    (save-current-buffer
      (set-buffer (get-buffer-create
		   po-pepm-buf-b-name))
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert msgid)
      (goto-char (setq beg-B (point-min)))
      (push-mark (setq end-B (point-max)) t t)
      (setq buffer-read-only t)
      (restore-buffer-modified-p nil))
    ;; run ediff
    (ediff-regions-internal
     (get-buffer po-pepm-buf-a-name) beg-A end-A
     (get-buffer po-pepm-buf-b-name) beg-B end-B
     nil 'ediff-regions-wordwise 'word-mode nil)
    )  ; end of let
  )

(provide 'po-ediff-previous-msgid)
;;; po-ediff-previous-msgid.el ends here
