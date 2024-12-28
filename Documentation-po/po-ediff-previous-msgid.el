;;; po-ediff-previous-msgid.el --- ediff previous-msgid & msgid.
;; Copyright (C) 2024 Kuma35
;; Author: kuma35
;; Maintainer: kuma35
;; Keywords: i18n gettext
;; Created: 2024/12/18 (year/month/day)
;; URL: https://github.com/kuma35/git-docs-ja
;; Package-Requires: (po-mode ediff)
;;; Commentary:
;; In po-mode,
;; Ediff-ing previous-msgid and msgid.
;; Previous msgid is  '#|' marked in comment.
;; Msgid is soruce sentence.
;; (Msgstr is translated sentence.)
;;
;; PEPM is my generate word.  PoEdiffPreviousMsgid.
;;
;; Development by po-mode 2.29, ediff 2.81.6, Emacs 29.3
;;
;; TODO: not support plural yet.
;;       (msgid_plural and msgstr[1] msgstr[2]
;;
;;; Change Log:
;; 2024/12/18 start development.
;; 2024/12/25 first release.
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

;; The registry of Ediff sessions.  A list of control buffers.")
(defvar ediff-session-registry)

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

(defcustom po-pepm-frame-name "*pepm-frame*"
  "Frame name for `po-ediff-previous-msgid` .
PEPM is PoEdiffPreviousMsgid."
  :type 'string
  :require 'po-mode
  :group 'po)


(defun po-popm-frame-named-list (name)
  "List if a frame with the given NAME exists."
  (let ((frames (frame-list))
        (result '())
	)
    (dolist (frame frames)
      (when (string= (frame-parameter frame 'name) name)
        (push frame result)
	)
      )
    result
    )
  )

(defun po-pepm-get-frame-create (name)
  "If NAME's frame is exist then return exists list.
Else is not exist then create frame by NAME."
  (let ((frames (po-popm-frame-named-list name))
	)
    (if frames
        frames
      (list (make-frame
	     `(
	       (name . ,name)
	       (fullscreen . maximized)
	       )
	     )
	    )
      )
    )
  )

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
	(frames          ; ediff target frames
	 (po-pepm-get-frame-create po-pepm-frame-name))
	(frame)
	)
    ;; nothing previous msgid then exit
    (if (not untranslated-regions)
	(error "Nothing previous msgid"))
    (if (not (null ediff-session-registry))
	; already exist ediff session
	(error "Please quit other Ediff session"))
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
    ;; chek frames and get a frame
    (if (> (length frame) 1)
      (progn
	(ding)
	(message "Multiple %s frames exist!"
		 po-pepm-frame-name)
	)
      )
    (with-selected-frame (car frames)
      ;; pepm-frame try to most front
      (select-frame-set-input-focus (selected-frame))
      ;; run ediff
      (ediff-regions-internal
       (get-buffer po-pepm-buf-a-name) beg-A end-A
       (get-buffer po-pepm-buf-b-name) beg-B end-B
       nil 'ediff-regions-wordwise 'word-mode nil)
      )
    )  ; end of let
  )

(provide 'po-ediff-previous-msgid)
;;; po-ediff-previous-msgid.el ends here
