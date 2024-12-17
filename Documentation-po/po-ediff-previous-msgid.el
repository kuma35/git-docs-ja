;; po-ediff-previous-msgid
;; previous msgid is  #| marked )
(defun po-ediff-previous-msgid ()
  "Ediff previous msgid (marked #| ) and msgid."
  (po-find-span-of-entry)
  (let ((msgid (po-get-msgid)))
    (with-current-buffer "*scratch*"
      (insert msgid))))
