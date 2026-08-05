# 目的

翻訳時に現在翻訳しているコマンド info について、
現在の翻訳と、過去の翻訳の diff を表示したいが、info同士のdiff表示は無理そう？

## ミニマムサクセス

- magit-find-file では指定のリビジョンのファイルを開くだけなので、 指定リビジョンの git.info や gitman.info ファイルを info ファイルとして開くコマンド。
- 現在手動で開いている最新の info と side by side で表示(split-window-horizontally)

ミニマムサクセスの時点で一度止める

## 理想

- side by side の info を diff 表示

## 実装状況

- 実装は `Documentation-po/elisp/` 以下(Emacs Lisp)。`~/.emacs.d/init.el` から
  `:load-path "~/work/git-docs-ja/Documentation-po/elisp/"` で読み込む
  (init.el 自体は本プロジェクト外)。
- `magit-find-info.el` — ミニマムサクセスのフル実装。`M-x magit-find-info` で
  リビジョンと `*.info` ファイルを補完入力で選び、指定リビジョンの内容を
  Info バッファとして右側に分割表示する。リビジョンのデフォルトは、HEAD から
  たどって最初に `*.info` が見つかったリビジョン。
  → 現状 **うまく動かない不具合があり未調査**(詳細は `magit-last-gitman.el`
  の Commentary を参照)。init.el では現在ロードしていない。
- `magit-last-gitman.el` — `magit-find-info.el` の不具合を受けて作った
  機能を絞り込んだ暫定版。プロンプトなしで、HEAD 時点の
  `Documentation-ja/gitman.info` だけを Info バッファとして開く。
  init.el から現在ロードしているのはこちら。
- TODO: `magit-find-info.el` の不具合を調査・修正し、`magit-last-gitman.el`
  を `magit-find-info.el` に統合(または不要になれば削除)する。
