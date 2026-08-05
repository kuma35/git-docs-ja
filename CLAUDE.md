# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクトの目的

このリポジトリは **git 本体の開発リポジトリ (git/git.git) のクローン** であり、その `Documentation/`
以下のドキュメントを日本語に翻訳する環境・作業リポジトリです。git 自体の開発(ビルド、C ソース、
Makefile 本体など)は対象外で、翻訳作業とそれを支えるツール群のみを扱います。

詳細仕様は必ず [Documentation-po/SPEC.md](Documentation-po/SPEC.md) を参照してください。本ファイルは
その要約 + Claude 向けの実務ガイドです。SPEC.md と内容が食い違う場合は SPEC.md を優先してください。

## 触ってよい範囲 / 触ってはいけない範囲

- **リポジトリルート直下のファイル(git 本体のソース・Makefile 等)は改変禁止。** これらは git 自体の
  開発用であり、翻訳プロジェクトとは無関係。
- 例外として改変・追加してよいのは以下のみ:
  - `Documentation/` — 翻訳対象の原文 (英語)。基本は触らないが、AsciiDoc の文法ミスなどでやむを得ず
    修正することがある。
  - `Documentation-sedout/` — 原文を po 化する前に機械的な前処理を行う中間フォルダ(翻訳プロジェクトが追加)。
  - `Documentation-po/` — po ファイル、ビルド/進捗管理スクリプト、進捗テキストなど翻訳作業の中枢。
    `Documentation-po/elisp/` には `~/.emacs.d/init.el`(本プロジェクト外)から読み込む
    Emacs Lisp 拡張スクリプトを置く(例: `magit-find-info.el`)。
  - `Documentation-ja/` — 翻訳済み成果物(info/html/texi 等)が生成される。
    ただし `Documentation-ja/RelNotes/` は**翻訳しない**。`Documentation/RelNotes/` の内容をそのまま
    コピーする扱い(po ファイルは msgid=msgstr のまま po4a を通すだけで、実質パススルー)。
    そのため `msgcount.sh` / `msgstat.sh` の集計対象からも `RelNotes/*.po` は除外されている。
  - `docs/` — GitHub Pages で公開するための静的サイト(ブランチごとのサブディレクトリを持つ)。
  - ルートの `.gitignore` — 翻訳作業で出る中間ファイルの追記のみ。

## ブランチ運用

- 翻訳作業は `docs-ja`, `docs-ja-2`, `docs-ja-3`, ... と git の新しいリビジョンを取り込むたびに新しい
  ブランチを切って進める。**現在の作業ブランチは `docs-ja-5`。**
- `docs/` 以下にも `docs-ja`〜`docs-ja-5` の各世代ディレクトリが並存し、過去バージョンの公開物も残す。

## ディレクトリ間のパイプライン

```
Documentation/          (原文 .adoc, 触らない)
      |  (Makefile 内で sed 等による機械的前処理)
      v
Documentation-sedout/   (前処理済み中間ファイル)
      |  (po4a により .pot/.po を生成・同期)
      v
Documentation-po/       (*.po, *.po4cfg, ビルド/進捗スクリプト)
      |  (msgmerge した po から翻訳済み .adoc を生成)
      v
Documentation-ja/       (翻訳済み .adoc → info/html/texi をビルド)
      |  (公開用に整形・コピー)
      v
docs/docs-ja-5/          (GitHub Pages 公開物: htmldocs/, info/, index.html)
```

- `Documentation-po/*.po4cfg` は各原文ファイルと po ファイルの対応(po4a 設定)を1ファイルずつ定義する。
- `Documentation-po/Makefile` がこのパイプライン全体(sedout 生成 → pot/po 同期 → 翻訳済み .adoc 出力)
  を駆動する。実行には `BRANCH=` の指定が必須(例: `BRANCH=docs-ja-5`)。

## よく使うコマンド

すべて `Documentation-po/` 以下で実行する想定(スクリプト内部で `cd` するものも多い)。

- **翻訳結果のビルド・公開反映**: `Documentation-po/compile.sh` (info のみ) / `Documentation-po/compile.sh html`
  (html も生成)。内部で python3 venv (`Documentation-po/venv/`) を有効化し、`make ja BRANCH=docs-ja-5` →
  `Documentation-ja/` で `make info` → `docs/docs-ja-5/` へ info/html を反映、というパイプライン全体を実行する。
  各段階でエラーがあれば `notify-send` で通知して即座に exit する。
- **翻訳進捗の集計**: `Documentation-po/msgcount.sh` — 全 po ファイルの翻訳済み/fuzzy/未翻訳メッセージ数と
  ファイル単位の進捗率を集計表示。
- **翻訳仕掛かり状況の一覧**: `Documentation-po/msgstat.sh` — 仕掛かり中(部分翻訳)の po ファイル一覧。
  `Documentation-po/msgstat.sh newbie` で未着手ファイルの一覧に切り替え。
- **TODO リストの再生成**: `(./msgstat.sh newbie; ./msgstat.sh) | gawk -f gen-translation-todo.awk` で
  `translation-todo.txt` (Emacs org-mode 形式) を再生成できる。

## 翻訳作業の詳細ワークフロー

- `Documentation-po/translation-todo.txt` を Emacs org-mode で開いて進捗管理する(`* DONE` / `* TODO`、
  `C-c C-t` でトグル)。各行は `翻訳済み+fuzzyf+未翻訳u  ファイル名` の形式。
- 個々の po ファイルは Emacs `po-mode` で編集する。このリポジトリ外の `~/.emacs.d/init.el` で
  po-mode コマンドを拡張している:
  - `j` (`po-kill-ring-save-msgid`): msgid を msgstr にコピーしつつ、msgid の内容もクリップボードにコピー。
  - `c` (`po-ediff-previous-msgid`): fuzzy エントリに previous msgid がある場合、previous と msgid の
    差分を ediff 表示。
- 翻訳自体は Emacs 上でコピーした msgid を外部 AI チャットに貼り付け、翻訳結果をコピーして msgstr に
  貼り戻すという半手動フロー(Google 翻訳連携もあるが精度が低いため現状ほぼ未使用)。
- 約10 ファイル翻訳するごとに、翻訳専用の GitHub リポジトリ `git-docs-ja` へ push して Web 公開する
  (`translation-todo.txt` 中の `# save point. git push for github page.` コメントが目安)。
- `compile.sh` 実行後、`restore-htmls.sh` / `restore-manpages.sh` が走り、日付やソース情報など
  意味のない差分だけの html/man ページを `git restore` で元に戻す(無駄な diff を防ぐため)。

## 現在進行中の改善事項 (SPEC.md より)

- 翻訳対象をまとめて AI (優先: Claude Code、次点: 無料版 Grok/Gemini への手動コピペ) に処理させ、
  結果を反映する仕組みの構築。トークン消費を抑える工夫が望ましい。
  → 独立リポジトリ `po-ai-assist` (https://github.com/kuma35/po-ai-assist) として実装済み。
- 今回翻訳した範囲を info/html レビュー時に一目で分かるようにする(現状は毎回全体を読み下す必要があり非効率)。
- po-mode の `c` コマンド(ediff 表示)の改善: 一時フレーム化して終了後に破棄する、または ediff を使わず
  po-mode 画面上で previous と msgid の差分をオーバーレイ表示する。
