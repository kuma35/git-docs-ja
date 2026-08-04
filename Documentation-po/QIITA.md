# title: git 付属ドキュメント翻訳

翻訳状況:
```
status by sentence: 25878+713f+508u
progress by sentence:25878/27099(95.49%)
progress by files: 283/399
2026年  8月  4日 火曜日 16:09:21 JST
```

# 成果物

https://kuma35.github.io/git-docs-ja/

# 現状
- git version 2.52.0.rc1.17.g4badef0c35 翻訳開始(2025/11/09)
- git version 2.47.1.404.ge66fd72e97 翻訳終了(2025/11/08)
- git version 2.41.0.337.g830b4a04c4 翻訳終了(2024/05/13)

## 翻訳した箇所

Document/ フォルダ内(RelNote/ 除く)を全訳済。未校正。

technical/ 内の文書は元々はASCIIDOCのみだったのも含めて全部html化してあります。

gitの最新版の翻訳反映はぼちぼちやっていきます。

## 日々の作業

### AIチャット貼り付けでの翻訳

ツール本体(`ai-translate.py` / `po-ai-translate.el`)は git-docs-ja 固有ではなく
汎用ツールとして独立リポジトリ [po-ai-assist](https://github.com/kuma35/po-ai-assist) に
切り出してあります。最新の使い方・設計判断は同リポジトリの README.md が正ですが、
冗長になりますがここにも使い方を残しておきます。

- `Documentation-po/translation-todo.txt` を Emacs org-mode で開いて進捗を確認します。
  各行は「翻訳済み+fuzzy+未翻訳 ファイル名」の形式で、po ファイル単位に `TODO`/`DONE` を
  トグル(`C-c C-t`)しながら消化していきます。
- 対象の po ファイルを Emacs `po-mode` で開き、po-ai-assist の `ai-translate.py` を使って
  AI に下訳させます。中心は **手動(manual)モード** です。
  1. po-mode で `C-c C-m` (`po-ai-translate-buffer-manual-export`) を実行する。
     内部で `ai-translate.py <file.po> --manual-export` が走り、未訳/fuzzy エントリ
     1バッチ分のプロンプトが `prompt.txt` に書き出される。 同時にクリップボード(kill-ring)にコピー。
  2. クリップボード(または `prompt.txt`)の内容を AI チャット(Grok、Gemini など)に貼り付ける。
  3. 結果のJSONをこれまたクリップボード経由で `response.json` に貼り付け「保存」する。(※保存してください。保存しないと実際に処理する python スクリプトが読み取れません)
  4. 対象の PO ファイルのバッファに戻り、 `C-c C-p` (`po-ai-translate-buffer-manual-apply`)を実行する。内部で
     `ai-translate.py <file.po> --manual-apply` が走り、po ファイルへ反映される。 ※対象の PO ファイルのバッファに戻らないとダメです。
  5. `response.json` のJSONエラーが無ければ(0)、適用完了OKで、 `prompt.txt` バッファと `response.json` バッファは削除されます。 JSON にエラーがあり正しく読み込めない(0以外)の時は適用できていません。 JSON を修正し `response.json` をセーブして再度`C-c C-p` (`po-ai-translate-buffer-manual-apply`)を実行してください。なお、終了コードが0以外の時は`prompt.txt` バッファと `response.json` バッファは削除されずに残ったままなので、必要に応じて手動で削除してください。
  - 1ファイルあたりの残エントリ数がデフォルトのバッチサイズ(30件)に収まれば、
    export→貼り付け→apply の1サイクルで1ファイル終わることが多いです。

### 自動で翻訳(claude 課金勢向け)

- **auto モード**(`C-c C-b` / `po-ai-translate-buffer`)もあります。こちらは
  `ai-translate.py <file.po>` を引数なしで実行し、内部で `claude -p --json-schema` を
  直接呼び出して翻訳〜po ファイルへの反映までを一括で行います(Claude API 課金が
  発生するため `--max-budget-usd` で上限を指定できます)。手動モードで手が回らない時や、
  まとめて流したい時に使います。
- 反映されたエントリには `# ai-translated` という翻訳者コメントが付き、fuzzy のまま
  残ります。これは「AI 訳を無条件に信頼しない」ための仕組みで、`grep` すれば今回
  AI が触った範囲だけを一覧できます(レビューして OK なら fuzzy を手動で解除)。
  同じマーカーが付いたエントリは以降の実行では対象から外れるので、レビュー前の
  エントリが再翻訳されて余計に課金される心配はありません。

### 翻訳の反映
  
- 翻訳の途中経過でも完了後でも、確認したくなったら `Documentation-po/compile.sh` を
  実行してビルドします(`html` を付けると html も生成、付けないと info のみ)。
- だいたい 10 ファイル訳すごとに、翻訳専用の GitHub リポジトリ `git-docs-ja` へ push して
  Web に反映しています。
  
### 原文の修正

- Asciidoc文法に従って無かった等の理由で、たまに原文(`Documentation/`)を修正する必要があります。
- 原文を修正した時も `Documentation-po/compile.sh` を走らせてください。 原文から PO ファイル更新を自動で行います。
- 編集中のPOファイルは開きなおすなどして編集を続行してください。

### 進捗確認

`./msgcount.sh` 現在の日付時刻と、翻訳の進捗状況をプリント。全体センテンス数、fuzzy数、未訳数、進捗パーセンテージ。
日々の進捗確認に使うほか、github への push の都度、出力をこの `QIITA.md` 先頭の
翻訳状況ブロックに貼り付けて更新しています。

`./msgstat.sh` newbee オプション(ハイフン無し)で未着手、オプション無しで仕掛のファイルリストをプリント。

## ai-translate.py の設計判断(補足)

コマンドの挙動を理解する上で最低限知っておくと良い点だけ挙げます(詳細・最新版は
[po-ai-assist](https://github.com/kuma35/po-ai-assist) リポジトリの README.md を参照)。

- po ファイルへの書き戻しは、`msgcat` によるファイル全体の再整形では行いません
  (既存の翻訳済み行まで再ラップされて壊れるため)。代わりに変更対象のバイト範囲だけを
  特定して置き換える「サージカル置換」方式を採っています。触っていないエントリは
  絶対に書き換わりません。
- `no-wrap` フラグ付きのエントリ(コマンド構文・見出し・オプションラベルなど)は、
  種類によって「msgid をそのまま返す(翻訳しない)」か「自然な日本語に訳す」かが
  `ai-translate-prompt.txt` 内のルールで指示されています。またアポストロフィ
  `'...'` はバッククォート `` `...` `` に変換する、といった info 向けの変換ルールも
  同ファイルにまとめてあります。
- fuzzy エントリ(原文が更新されたもの)は `previous_msgid`/`previous_msgstr` も
  プロンプトに含め、旧訳文の語彙・言い回しをできるだけ維持したまま差分だけを
  更新するよう指示しています。
- `--selftest --root <dir>` で、指定ディレクトリ配下の po コーパス全体に対して
  自前のパーサ(バイトオフセット走査)と `polib` のパース結果が食い違っていないかを
  チェックできます。

# 新しいリビジョンへの対応(新しい docs-ja- ブランチを切る)

git 本体の新しいリビジョンに追随するときは、都度新しい `docs-ja-N` ブランチを切って作業します
(現在は `docs-ja-5`)。おおまかな手順は以下の通りですが、リビジョンごとに事情が変わるので、
このセクションは今後も追記・更新していく予定です。

- 新しい `docs-ja-N` ブランチを作成し、upstream (`git/git`) の最新を取り込む。 upstream は 直接リポジトリではなくて、
  git リポジトリから取ってきたのを `~/work/git/` に clone したのを upstream としている。なんでそうしたのかは忘れたスマン。
  `Documentation/` 側で発生する CONFLICT を解決する。
- 原文ファイルの増減に合わせて `Documentation-po/Makefile` や各種 `*.po4cfg` を追記・削除する。
- `Documentation-po/compile.sh` や `index.html.template`、`docs/index.html` など、
  ブランチ名(`BRANCH=docs-ja-N`)がハードコードされている箇所を新ブランチ用に書き換える。
- `docs/docs-ja-N/` を新設し、一度 `make` を通して po4a のパースやビルドが正常に通るか
  試験的に流してみる(拡張子の変更や asciidoc 記法の変化など、リビジョンごとに細かい非互換が
  出ることがある)。
- 問題なければ通常の「日々の作業」フローに合流し、翻訳を進めていく。

# ハイライト

古い作業ログです。2022 年頃までの主要な進捗はこちらに、それ以降の状況は上の「現状」を
参照してください。

- 2.38.0.rc1.232.gf2a34720e0.dirty に対応 (2022.10)
- 全訳出。未校正(2022.9)
- howto 文書 全てを訳出(未校正) (2022.7)
- git command 全てを訳出(未校正) (2022.7)
- technical フォルダ下のドキュメントへのリンクを追加(訳出分のみ)(2022.5)
- gitの概念に関するドキュメントを訳出(2022.4)
- git-config訳出(2022.4)

# man page 対応

man page の生成に対応しています。`Documentation-ja/` の `*.1` `*.5` `*.7` を、
インストール先の man ディレクトリ(Ubuntu なら `/usr/share/man/ja/` の対応フォルダ)へ
それぞれコピーしてください。

※ `Documentation/`、`Documentation-ja/` の Makefile から `install` すると
`/usr/share/man` 直下にインストールされてしまうので注意してください。

# 何か?

git 本体の開発リポジトリ(https://github.com/git/git )の `Documentation/` フォルダの
翻訳プロジェクトです。git 自体の開発(ビルドや C ソース)は対象外で、ドキュメントの
日本語訳とそれを支えるツール群のみを扱っています。

# 使い方

https://kuma35.github.io/git-docs-ja/

html版、INSTALLテキスト、info など(未翻訳含む)を置いてあります。トップページから
`docs-ja` 〜 `docs-ja-5` の各世代(対応する git のバージョンごと)のドキュメントに
リンクしています。最新版は `docs-ja-5` (git 2.52.0.rc1 系)です。

過去バージョンが見たい場合は、github のリポジトリを clone して該当する `docs-ja-N`
ブランチを選択してください。

# リポジトリ

https://github.com/kuma35/git-docs-ja

の `docs-ja-5` ブランチ(最新)から、`Documentation` の翻訳が `Documentation-ja` フォルダに
入っています。未翻訳の部分はそのままです。過去のリビジョンは `docs-ja`、`docs-ja-2` 、
`docs-ja-3`、`docs-ja-4` の各ブランチに残しています。

生成した info や html は `docs/` フォルダ(ブランチごとに `docs/docs-ja-N/` のサブフォルダ)
に入っています。

- infoでチェックしながら作成しています。
- 手元のinfoではロングオプション `--` をダッシュ(長ダッシュ?)に変換してしまいますので、オプションのタイトルに関してはバッククォートで囲って変換しないようにしてあります。※Synopsisの中は長ダッシュになってしまっています。今の所解決できていません。
- htmlは一応生成していますが全然チェックしていません。

## ビルド
Documentation-poフォルダ内で compile.sh を実行します。
引数は MAKEILE で受け付けるものです。何もつけなくても info がデフォルトで指定してあります。 html を指定すると html も生成します。
html生成時は内容のチェック(diff)を行い、以前とタイムスタンプ以外同じhtmlであった場合は `git restore` しています。

infoと html 以外はチェックしてないのでコケるかもしれません。

デスクトップに notify を送っています。適宜各自の環境に合せて修正してください。

## その他スクリプト
`msgcount.sh` は po ファイルの全体進捗を表示します。

`msgstat.sh` は仕掛り中の po ファイルを表示します。`msgstat.sh newbie` で未着手ファイルの
一覧に切り替わります。

`(./msgstat.sh newbie; ./msgstat.sh) | gawk -f gen-translation-todo.awk` で、上の
「日々の作業」で使っている `translation-todo.txt` (Emacs org-mode 形式)を再生成できます。

## フォルダ構成
`Documentation/` 元々あるフォルダ。ASCIIDOC のテキストが入っている。po4aのパース(parse)改善の為時々この原文を修正掛けてあるので注意。

`Documentation-sedout/` 主にオプションの `--` がinfoで長ダッシュに変換されてしまうのを防ぐための変換結果が入る(compile.sh中で処理)。注意:poファイルから s コマンドでソースを表示した時に見えるのは Documentation/ ではなくて この Documentation-sedout/ なので注意。いくらそれを編集しても無効。手動で対応する Documentation/ のファイルを開いて編集する必要ある。

`Documentation-po/` po4aにより生成されたpoファイルがココに入る。このpoファイル群をせっせと翻訳する。各種自作スクリプトもココに入っている。

`Documentation-ja/` 翻訳後のファイルが入る。翻訳の必要が無いファイルも Documentation/ と同じ環境を造るために自動でコピーしてくる(compile.sh)。ただし `RelNotes/` のみ翻訳対象外で、原文をそのままコピーしています。

`docs/` github pages 公開用のフォルダ。ブランチ(世代)ごとに `docs-ja/`、`docs-ja-2/` 、…、`docs-ja-5/` のサブフォルダに分かれています。

## docs/index.html
直接編集せずに、`Documentation-po/index.html.template` を編集してください。これを `docs/docs-ja-N/index.html` へ転送しています(トップの `docs/index.html` 自体は各世代へのリンク一覧で、こちらは手編集です)。

# 元

https://github.com/git/git

# なぜ訳したか

## 当時、巷には機械翻訳っぽいのが多かった
プログラマとしては、読んでコマンドなり操作の意味が分からんのは困るので、時々当該コマンドを叩きながら意訳したり。

## 持続的開発目標
流行りの SDGs です 持続的翻訳です。 巷の翻訳は大変ありがたいのですが、それを更に(自分で)更新していく方法が分かりません。

あわよくばだれかが肩代わりしてくれると嬉しいななんて思います。

こちらさんを参考にさせてもらってます。

https://qiita.com/ayatakesi/items/a8a6a9bb2df6c4511185

