;;; magit-find-info.el --- open a *.info file at a revision as an Info buffer.
;; Copyright (C) 2026 Kuma35
;; Author: kuma35
;; Maintainer: kuma35
;; Keywords: i18n gettext info
;; Created: 2026/08/03 (year/month/day)
;; URL: https://github.com/kuma35/git-docs-ja
;; Package-Requires: (magit info)
;;; Commentary:
;; 指定したリビジョン(ブランチ・コミット)時点の *.info ファイルを
;; Info バッファとして開き、現在のウィンドウの右側に分割して表示する。
;;
;; magit-find-file は指定リビジョンのファイルをそのまま(テキストとして)
;; 開くだけなので、info フォーマットとしてノード遷移などができる形で
;; 開けるようにしたもの。
;;
;; 翻訳中に、現在の翻訳(まだ commit していない/最新の作業ブランチ上の
;; git.info 等)と、過去の翻訳(別ブランチや過去のコミット時点の内容)を
;; 並べて見比べる用途を想定している。git.info/gitman.info に限らず、
;; リポジトリ内の *.info ファイルであれば何でも開ける。
;;
;; Documentation-po/SPEC-magit-find-info.md のミニマムサクセスに対応する
;; 実装。理想(side by side の info を diff 表示)は未実装。
;;
;; Development by magit, Emacs 29.3
;;
;;; Change Log:
;; 2026/08/03 start development. (minimum success)
;; 2026/08/03 generalize to any *.info file, drop po- prefix.
;; 2026/08/03 default revision: walk back from HEAD to nearest revision
;;            containing a *.info file.
;;; Code:

(declare-function
 magit-read-branch-or-commit "magit-git" (prompt &optional secondary-default))
(declare-function magit-toplevel "magit-git" (&optional directory))
(declare-function magit-git-lines "magit-git" (&rest args))
(declare-function magit-git-insert "magit-process" (&rest args))

(defun magit-find-info--list-files (rev)
  "REV 時点でリポジトリに存在する *.info ファイルの一覧を返す。"
  (let ((default-directory (magit-toplevel)))
    (magit-git-lines "ls-tree" "-r" "--name-only" rev "--" "*.info")))

(defun magit-find-info--default-revision ()
  "HEAD からたどって最初に *.info ファイルが見つかったリビジョンの
コミットハッシュを返す。見つからなければ \"HEAD\" を返す。
このリポジトリは git/git 本体の全履歴を持つため、たどる際は
`git log -- pathspec' で履歴を絞り込む(全コミットを列挙して
1つずつ ls-tree するのは重すぎるため使わない)。"
  (let ((default-directory (magit-toplevel)))
    (or (car (magit-git-lines "log" "--format=%H" "-1" "HEAD" "--" "*.info"))
        "HEAD")))

(defun magit-find-info--default-file (candidates)
  "現在の Info バッファに対応するファイルを CANDIDATES から推測する。
推測できなければ nil を返す。"
  (when (and (derived-mode-p 'Info-mode)
             (boundp 'Info-current-file)
             (stringp Info-current-file))
    (let ((name (file-name-nondirectory Info-current-file)))
      (seq-find (lambda (f) (string= (file-name-nondirectory f) name))
                candidates))))

(defun magit-find-info--read-file (rev)
  "REV 時点に存在する *.info ファイルの中から開くファイルを補完入力で選択する。"
  (let ((candidates (magit-find-info--list-files rev)))
    (unless candidates
      (user-error "%s に *.info ファイルが見つかりません" rev))
    (completing-read (format "Info file (%s): " rev) candidates nil t nil nil
                      (magit-find-info--default-file candidates))))

(defun magit-find-info (rev file)
  "REV 時点の FILE (リポジトリ内の *.info ファイル) を Info バッファとして
開き、現在のウィンドウの右側に分割 (side-by-side) して表示する。
FILE はリポジトリルートからの相対パスを指定する。"
  (interactive
   (progn
     (require 'magit)
     (let* ((rev (magit-read-branch-or-commit
                  "Revision" (magit-find-info--default-revision)))
            (file (magit-find-info--read-file rev)))
       (list rev file))))
  (require 'magit)
  (require 'info)
  (let* ((repo-root (magit-toplevel))
         (blob (format "%s:%s" rev file))
         (tempfile (make-temp-file "magit-find-info-" nil ".info"))
         (buffer-name (format "*info %s (%s)*" (file-name-nondirectory file) rev)))
    ;; 指定リビジョンでの blob 内容を一時ファイルに書き出す。
    ;; Info-find-node はディレクトリ付きパスならそのまま読めるので、
    ;; Info-directory-list に登録しなくても開ける。
    (with-temp-file tempfile
      (let ((default-directory repo-root))
        (magit-git-insert "show" blob)))
    (select-window (split-window-horizontally))
    (info tempfile buffer-name)
    ;; バッファを閉じたら一時ファイルも削除する。
    (add-hook 'kill-buffer-hook
              (let ((f tempfile))
                (lambda () (ignore-errors (delete-file f))))
              nil t)))

(provide 'magit-find-info)
;;; magit-find-info.el ends here
