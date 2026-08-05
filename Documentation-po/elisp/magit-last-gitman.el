;;; magit-last-gitman.el --- open HEAD's Documentation-ja/gitman.info as an Info buffer.
;; Copyright (C) 2026 Kuma35
;; Author: kuma35
;; Maintainer: kuma35
;; Keywords: i18n gettext info
;; Created: 2026/08/03 (year/month/day)
;; URL: https://github.com/kuma35/git-docs-ja
;; Package-Requires: (magit info)
;;; Commentary:
;; magit-find-info.el がうまく動かなかったため、機能を絞り込んだ版。
;; プロンプトなしで、HEAD 時点の Documentation-ja/gitman.info を
;; Info バッファとして開くだけのコマンド。
;;
;;; Change Log:
;; 2026/08/03 start development.
;;; Code:

(declare-function magit-toplevel "magit-git" (&optional directory))
(declare-function magit-git-insert "magit-process" (&rest args))

(defconst magit-last-gitman-file "Documentation-ja/gitman.info"
  "HEAD から取り出す gitman.info のリポジトリ内パス。")

(defun magit-last-gitman ()
  "HEAD 時点の Documentation-ja/gitman.info を Info バッファとして開く。
バッファを閉じると、内容を書き出した一時ファイルも削除する。"
  (interactive)
  (require 'magit)
  (require 'info)
  (let* ((repo-root (magit-toplevel))
         (blob (format "HEAD:%s" magit-last-gitman-file))
         (tempfile (make-temp-file "magit-last-gitman-" nil ".info")))
    (with-temp-file tempfile
      (let ((default-directory repo-root))
        (magit-git-insert "show" blob)))
    (info tempfile "*magit-last-gitman*")
    ;; バッファを閉じたら一時ファイルも削除する。
    (add-hook 'kill-buffer-hook
              (let ((f tempfile))
                (lambda () (ignore-errors (delete-file f))))
              nil t)))

(provide 'magit-last-gitman)
;;; magit-last-gitman.el ends here
