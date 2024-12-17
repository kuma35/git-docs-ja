;; po-ediff-previous-msgid
;; previous msgid is  #| marked )
;;(defgroup po nil
;;  "Major mode for editing PO files"
;;  :group 'i18n)

(defcustom po-ediff-previous-msgid-buffer-a-name "*pepm-previous-msgid*"
  "po-ediff-previous-msgid BUFFER A name. pepm is PoEdiffPreviousMsgid"
  :type 'string
  :require 'po-mode
  :group 'po)

(defcustom po-ediff-previous-msgid-buffer-b-name "*pepm-now-msgid*"
  "po-ediff-previous-msgid BUFFER A name. pepm is PoEdiffPreviousMsgid"
  :type 'string
  :require 'po-mode
  :group 'po)


(defun po-ediff-previous-msgid ()
  "Ediff previous msgid (marked #| ) and msgid."
  (po-find-span-of-entry)
  (let (
	(msgid (po-get-msgid))
	)
    (save-current-buffer
      (set-buffer (get-buffer-create
		   po-ediff-previous-msgid-buffer-b-name))
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert msgid)
      (restore-buffer-modified-p nil)
      (setq buffer-read-only t))))
