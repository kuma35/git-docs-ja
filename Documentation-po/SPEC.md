# SPEC.md

## 目的

(`CLAUDE.md` の再掲です)

git 自体の開発プロジェクトである clone の、
`Document/` フォルダ以下のドキュメントを翻訳(日本語訳)する環境の改善プロジェクト 


## 対象フォルダ制約

- 以下表記、 `CLAUDE.md` を置いたフォルダをプロジェクトルートとします。 現状は `PROJ_ROOT=~/work/git-docs-ja` です。
  以下はプロジェクトルートからの相対です。

- この翻訳プロジェクトはブランチ `docs-ja-5` 上。 `docs-ja` 、 `docs-ja-2` ... と始まり、今は `docs-ja-5` です。 git の新しいレビジョンを翻訳開始するときに新しいブランチを切る。 現在の翻訳は `docs-ja-5` で行います。

- 基本: `$PROJ_ROOT/*` 全体は基本は改変禁止。 Makefile 等も一切取り扱わなくてよい。これらは git 自体の開発のためであり
ドキュメントのためではない。

基本は上記として、例外的に以下、

- `$PROJ_ROOT/.gitignore` 翻訳作業に従って出る中間ファイル等を追記。
- `$PROJ_ROOT/Document/` は翻訳対象となる原文(英文)のフォルダ。基本はいじらないが、 Asciidoc 文法ミス等によりどうしても
  原文をいじらなければならないことがある。
- `$PROJ_ROOT/Documentation-sedout/` 翻訳プロジェクトで追加したフォルダ。原文を po ファイルに変換する前に機械的に可能な処理を行う。
- `$PROJ_ROOT/Documentation-po/` po ファイルと、翻訳作業を制御するスクリプト、進捗テキストファイル等がある
- `$PROJ_ROOT/Documentation-ja/` 翻訳済みが入る
- `$PROJ_ROOT/docs/` 翻訳済みを github webpage で公開するためのフォルダ

## 新しいgitレビジョンの翻訳開始

- ※今回の改善作業には直接関係無いので割愛します。
- このレビジョンで一度だけ行う操作。新しい docs-ja-9999 ブランチを切り、上流から新しいレビジョンを pull し、(Documentの)CONFLICTをがんばって解決する。
- 対象ファイルが増えたら Documentation-po/Makefile に追記したり、減ったら削除したりする
- 正常に翻訳作業ができるかテストラン

## 日常の翻訳作業の流れ

- `Documentation-po/translation-todo.txt` を Emacs org-mode で開き、作業進捗を確認する。
- 対象 po ファイルの翻訳作業
- 対象 po ファイルの翻訳途中でも翻訳終了でも、結果が確認したくなったら、
  `Documentation-po/compile.sh html` を実行する。 `html` を付けると `html` ファイルを生成、
  付けないと info ファイルだけ生成する。
- おおよそ 10 翻訳するごとに翻訳専用の github git-docs-ja リポジトリへ push し、Webに公開する。

### 対象 po ファイルの翻訳作業詳細

- Emacs po-mode で閲覧・編集
- po-mode コマンドを拡張・追記している(本プロジェクト外 `~/.emacs.d/init.el` なので参照したい時は操作方法を指示して)。
  j コマンド拡張(`po-kill-ring-save-msgid`)。msgid を msgstr に上書きするコマンドだが、 拡張としてクリップボードに msgid の内容をコピー。
  追加コマンドは c (`po-ediff-previous-msgid`)で、 fuzzy で previous がある場合に、 previous と msgid の内容を比較し ediff 表示する。
- Emacs `google-translation` を使って google 翻訳が使えるようにしてあるが、翻訳精度が悪いので今はほとんど使わない。
- msgstrの編集モードにした状態でEmacsのコマンドで普通にコピーしたものを各種AIチャットに貼り付けて、翻訳結果を再びコピーで持ってくることにより翻訳している。


## 今回行いたい改善

- 翻訳対象をまとめてAIに処理してもらい、翻訳結果を反映する。
- 処理するAIは claude code を現状では最優先とする。できればお財布に優しいよう、消費トークンが少なくなる提案があると良い。
- 処理するAIは次点で無料版の Grok チャットへの手動貼り付け・手動コピペを考えている(他に無料の gemini)。
- 今回翻訳した範囲が info (または web) でレビューする時に判るようにする。今までは毎回コマンド全体を読み下すのでとても時間がかかっている。
- po-mode の c コマンドの改善。今は別途Emacsフレームを開いているが、 1. フレームをテンポラリとし、
  コマンド終了後は都度削除、2. そもそもEdiff表示せず、 Emacs po-mode 画面で、 previous と msgid に相違箇所オーバーレイ(ハイライト)するともっとよい。
