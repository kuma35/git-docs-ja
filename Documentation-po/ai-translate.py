#!/usr/bin/env python3
"""Batch-translate untranslated/fuzzy entries of a Documentation-po/*.po file via `claude -p`.

JP:
使い方:
    Documentation-po/venv/bin/python3 Documentation-po/ai-translate.py --selftest
    Documentation-po/venv/bin/python3 Documentation-po/ai-translate.py <file.po> --dry-run
    Documentation-po/venv/bin/python3 Documentation-po/ai-translate.py <file.po> [options]

`claude -p` を使わず、無料の AI チャット(ブラウザ版 ChatGPT/Gemini 等)へ手動でコピペする
場合は以下の2段階で使う(課金無し):
    Documentation-po/venv/bin/python3 Documentation-po/ai-translate.py <file.po> --manual-export
        (出力される MANUAL_PROMPT_FILE= のファイルをチャットに貼り、返ってきた JSON を
        MANUAL_RESPONSE_FILE= のファイルへ保存する)
    Documentation-po/venv/bin/python3 Documentation-po/ai-translate.py <file.po> --manual-apply

--manual-paths は上記2つのファイルパスを問い合わせるだけのクエリ専用コマンド(export 未実行でも
安全に呼べる)。Emacs 側が「前回 export 時のバッファローカル変数」に頼らず、po ファイルのパスから
毎回パスを再導出するために使う。

設計方針: polib はエントリの「パース」専用に使う(msgid/msgstr/previous_msgid/flags を、
エスケープ解除済みの値として取得するだけ)。元ファイルへのバイト範囲差し替えは、
raw テキストを別途構造的に走査して行う(PO 構文の行頭プレフィックスだけを見て、
文字列の中身はデコードしない)。これにより、触っていないエントリは絶対に
再ラップ/再整形されず、実際に翻訳したエントリだけが書き換えられる。
プロジェクトの背景は Documentation-po/SPEC.md と CLAUDE.md を参照。

翻訳結果は無条件には信頼しない: 翻訳したエントリは fuzzy のまま残す(または新たに
fuzzy 化する)うえで、「# ai-translated」という翻訳者コメントを付与する。
これにより、人間が fuzzy を解除する前に、その範囲を grep で検索して
po-mode/info/html 上でレビューできる。既にマーク済みのエントリは以降の実行での
対象選定から除外する(fuzzy であるというだけでは対象から外れないため、これがないと
fuzzy のままの AI 翻訳済みエントリが実行のたびに再翻訳・再課金され続けてしまう)。
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    import polib
except ImportError:
    sys.exit(
        "polib is required. Install it into the project venv:\n"
        "  Documentation-po/venv/bin/pip install polib"
    )

SCRIPT_DIR = Path(__file__).resolve().parent
PROMPT_FILE = SCRIPT_DIR / "ai-translate-prompt.txt"
WRAP_WIDTH = 79
AI_MARKER = "ai-translated"
MANUAL_SESSION_ROOT = Path(tempfile.gettempdir()) / "git-docs-ja-ai-translate"

# obsolete エントリ ("#~ msgid ...") はコメントアウトされているが polib の通常の
# イテレーションでもカウントされるので、block-scanning の対応を保つため
# これらの正規表現は "#~ " プレフィックスの有無を両方受け付ける。
MSGID_RE = re.compile(r'^(?:#~\s*)?msgid(?!_plural)\s')
MSGID_PLURAL_RE = re.compile(r'^(?:#~\s*)?msgid_plural\s')
MSGSTR_RE = re.compile(r'^(?:#~\s*)?msgstr\s')
MSGCTXT_RE = re.compile(r'^(?:#~\s*)?msgctxt\s')
FLAGS_RE = re.compile(r'^#,')
PREV_RE = re.compile(r'^#~?\|')


class FormatAssumptionError(RuntimeError):
    """Raised when a .po file uses a construct this tool doesn't support (msgctxt, plural forms)."""


def split_blocks(text):
    """Split file text into blank-line-separated blocks, returning (start, end) spans.

    JP:
    最終ブロック以外は、末尾の改行を自然に含まない(m.start() は "\\n\\n" 区切りの
    直前、つまり実コンテンツの最後の文字の直後を指す)。しかしファイル末尾のブロックだけは
    そのままだとファイルの末尾改行を含んでしまうため、ここで1文字だけ取り除き、
    ファイル中の位置に関わらずどのブロックも「内容の直後で終わる」形に揃える。
    """
    spans = []
    pos = 0
    for m in re.finditer(r'\n\n+', text):
        spans.append((pos, m.start()))
        pos = m.end()
    end = len(text)
    if end > pos and text[end - 1] == "\n":
        end -= 1
    spans.append((pos, end))
    # 末尾の空行によって生じうる、空のブロックを除外する。
    return [(s, e) for s, e in spans if text[s:e].strip()]


def scan_block(block_text, block_start):
    """Locate the structural line offsets of one PO entry block (absolute offsets in the file)."""
    lines = block_text.splitlines(keepends=True)
    offsets = []
    pos = block_start
    for line in lines:
        offsets.append(pos)
        pos += len(line)
    block_end = pos

    flags_idx = None
    prev_idxs = []
    msgid_idx = None
    msgstr_idx = None
    for i, line in enumerate(lines):
        if MSGCTXT_RE.match(line):
            raise FormatAssumptionError("msgctxt is not supported by this tool")
        if MSGID_PLURAL_RE.match(line):
            raise FormatAssumptionError("msgid_plural is not supported by this tool")
        if FLAGS_RE.match(line) and flags_idx is None and msgid_idx is None:
            flags_idx = i
        elif PREV_RE.match(line):
            prev_idxs.append(i)
        elif MSGID_RE.match(line) and msgid_idx is None:
            msgid_idx = i
        elif MSGSTR_RE.match(line) and msgstr_idx is None:
            msgstr_idx = i

    if msgid_idx is None or msgstr_idx is None:
        raise FormatAssumptionError(f"block has no msgid/msgstr line: {block_text[:80]!r}")

    return {
        "flags_start": offsets[flags_idx] if flags_idx is not None else None,
        "flags_end": (offsets[flags_idx] + len(lines[flags_idx])) if flags_idx is not None else None,
        "prev_end": (offsets[prev_idxs[-1]] + len(lines[prev_idxs[-1]])) if prev_idxs else None,
        "msgid_start": offsets[msgid_idx],
        "msgstr_start": offsets[msgstr_idx],
        "block_end": block_end,
    }


class Entry:
    def __init__(self, index, po_entry, block_span, struct):
        self.index = index
        self.po_entry = po_entry
        self.block_span = block_span
        self.struct = struct

    @property
    def is_untranslated(self):
        e = self.po_entry
        return e.msgstr == "" and not e.fuzzy and not e.obsolete

    @property
    def is_fuzzy(self):
        return self.po_entry.fuzzy and not self.po_entry.obsolete

    @property
    def is_nowrap(self):
        return "no-wrap" in self.po_entry.flags

    @property
    def is_ai_marked(self):
        # 過去の実行でこのツールにより既に処理済み。対象選定から除外しないと、
        # fuzzy のままの AI 翻訳済みエントリが実行のたびに再翻訳(再課金)され続けてしまう。
        return AI_MARKER in (self.po_entry.tcomment or "")


def load_entries(po_path):
    text = Path(po_path).read_text(encoding="utf-8")
    blocks = split_blocks(text)
    if not blocks:
        raise FormatAssumptionError(f"{po_path}: no entries found")

    # blocks[0] は PO ヘッダエントリ(msgid が空)であり翻訳対象外。obsolete ("#~") な
    # ブロックは除外せず残す: polib 自体のイテレーションも obsolete エントリを含む
    # (obsolete_entries() は別リストではなく単なるフィルタ済みビューにすぎない)ため、
    # 件数を揃えるには含める必要がある。
    entry_blocks = blocks[1:]
    pofile = polib.pofile(str(po_path))

    if len(pofile) != len(entry_blocks):
        raise FormatAssumptionError(
            f"{po_path}: polib found {len(pofile)} entries but text scan found "
            f"{len(entry_blocks)} blocks (excluding header) -- parser mismatch, aborting"
        )

    entries = [
        Entry(i, po_entry, (s, e), scan_block(text[s:e], s))
        for i, (po_entry, (s, e)) in enumerate(zip(pofile, entry_blocks))
    ]
    return text, entries


def _flags_text(text, struct):
    if struct["flags_start"] is None:
        return ""
    end = struct["prev_end"] if struct["prev_end"] is not None else struct["msgstr_start"]
    return text[struct["flags_start"]:end]


def cross_check(text, entries, po_path):
    """Defense-in-depth: verify fuzzy-ness agrees between polib and the structural scan."""
    problems = []
    for entry in entries:
        flags_text = _flags_text(text, entry.struct)
        scan_says_fuzzy = "fuzzy" in flags_text
        if scan_says_fuzzy != entry.po_entry.fuzzy:
            problems.append(
                f"{po_path}: entry #{entry.index} fuzzy mismatch "
                f"(polib={entry.po_entry.fuzzy}, scan={scan_says_fuzzy})"
            )
    return problems


def iter_po_files(root):
    for path in sorted(root.rglob("*.po")):
        if "RelNotes" in path.parts or "venv" in path.parts:
            continue
        if path.name.startswith(".#"):
            # Emacs のロックファイル(シンボリックリンク)。実体を持たないため除外する。
            continue
        yield path


def cmd_selftest(args):
    root = SCRIPT_DIR
    total = 0
    failed = 0
    for path in iter_po_files(root):
        total += 1
        try:
            text, entries = load_entries(path)
            problems = cross_check(text, entries, path)
            if problems:
                failed += 1
                for p in problems:
                    print(f"FAIL {p}")
        except FormatAssumptionError as e:
            failed += 1
            print(f"FAIL {path}: {e}")
    print(f"\n{total} files scanned, {failed} failed.")
    return 1 if failed else 0


def assert_not_relnotes(po_path):
    if "RelNotes" in Path(po_path).resolve().parts:
        sys.exit(f"refusing to process RelNotes file (not translated by project policy): {po_path}")


def select_targets(entries, only_untranslated, only_fuzzy, limit):
    if only_untranslated:
        targets = [e for e in entries if e.is_untranslated]
    elif only_fuzzy:
        targets = [e for e in entries if e.is_fuzzy]
    else:
        targets = [e for e in entries if e.is_untranslated or e.is_fuzzy]
    targets = [e for e in targets if not e.is_ai_marked]
    if limit is not None:
        targets = targets[:limit]
    return targets


def sample_few_shot(entries, n):
    out = []
    for e in entries:
        if len(out) >= n:
            break
        pe = e.po_entry
        if (pe.translated() and not pe.fuzzy and not e.is_ai_marked
                and pe.msgid and len(pe.msgid) <= 200):
            out.append({"msgid": pe.msgid, "msgstr": pe.msgstr})
    return out


def build_batches(targets, batch_size):
    for i in range(0, len(targets), batch_size):
        yield targets[i:i + batch_size]


def session_paths(po_path):
    """手動モードのセッション用ディレクトリと3ファイルのパスを返す(無ければ作成する)。

    JP: po ファイルの絶対パスから決定的にディレクトリ名を導出するため、export/apply を
    別プロセス・別タイミングで実行しても(Emacs 側から見ても)常に同じパスになる。
    """
    resolved = str(Path(po_path).resolve())
    slug = re.sub(r"[^A-Za-z0-9]+", "_", resolved).strip("_")
    session_dir = MANUAL_SESSION_ROOT / slug
    session_dir.mkdir(parents=True, exist_ok=True)
    return {
        "dir": session_dir,
        "prompt": session_dir / "prompt.txt",
        "session": session_dir / "session.json",
        "response": session_dir / "response.json",
    }


def command_meta_for_path(po_path):
    """ファイル名からコマンド名を導出する ("git-diff.po" -> "git diff")。

    JP: "git" 接頭辞の直後を1個だけ空白に置き換える ("git-diff" -> "git diff")。
    それ以降に残るハイフンはサブコマンド名自体の一部なので変更しない
    ("git-commit-graph" -> "git commit-graph")。gitattributes.po や gitk.po の
    ように "git" の直後にハイフンが無い名前も、info では実際にコマンド名として
    引ける項目なので、同じ扱いで "git attributes" のように強引にコマンド名化する。
    "git" 以外で始まるファイル (technical/*.po 等) はコマンドと無関係なので None。
    """
    stem = Path(po_path).stem
    if not stem.startswith("git"):
        return None
    body = stem[len("git"):].removeprefix("-")
    return f"git {body}" if body else "git"


def build_prompt(preamble, few_shot, batch, command_meta=None, include_schema_text=False):
    items = []
    for e in batch:
        pe = e.po_entry
        item = {"id": e.index, "msgid": pe.msgid, "no_wrap": e.is_nowrap}
        if e.is_fuzzy:
            item["previous_msgid"] = pe.previous_msgid or ""
            item["previous_msgstr"] = pe.msgstr
        items.append(item)

    parts = [preamble]
    if command_meta:
        parts.append(f"\n# 対象コマンド\nこのファイルは `{command_meta}` コマンドのドキュメントです。")
    if few_shot:
        parts.append("\n# 参考: このファイル内の既存の訳例\n" + json.dumps(few_shot, ensure_ascii=False, indent=2))
    if include_schema_text:
        # claude -p の --json-schema はプロンプト外から出力形式を強制するが、
        # 無料 AI チャットにはその強制力が無いため、スキーマと出力例をテキストとして
        # 明示的に埋め込む(手動モード専用)。
        parts.append(schema_instructions_text(items))
    parts.append("\n# 翻訳対象\n以下の各エントリを翻訳し、指定された JSON 形式で返してください。\n"
                  + json.dumps(items, ensure_ascii=False, indent=2))
    return "\n".join(parts)


SCHEMA = {
    "type": "object",
    "properties": {
        "translations": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "integer"},
                    "msgstr": {"type": "string"},
                },
                "required": ["id", "msgstr"],
            },
        },
    },
    "required": ["translations"],
}


def schema_instructions_text(items):
    """手動モード用: JSON スキーマと出力例を人間可読テキストとして生成する。

    JP: claude -p では --json-schema フラグがこの役割を代替するが、無料 AI チャットには
    その強制力が無いため、スキーマ本体と具体的な出力例をプロンプト内に埋め込む。
    """
    example = {
        "translations": [
            {"id": item["id"], "msgstr": "(ここに翻訳結果を書く)"} for item in items[:2]
        ]
    }
    return (
        "\n# 出力形式\n"
        "回答は以下の JSON スキーマに従う JSON オブジェクトのみを出力してください。\n"
        "前置き・後書き・コードフェンス(```)などの説明は一切付けないでください。\n\n"
        "## スキーマ\n" + json.dumps(SCHEMA, ensure_ascii=False, indent=2) + "\n\n"
        "## 出力例(id は下記の翻訳対象と対応させること)\n"
        + json.dumps(example, ensure_ascii=False, indent=2)
    )


def call_claude(prompt, model, max_budget_usd):
    cmd = ["claude", "-p", prompt, "--output-format", "json",
           "--json-schema", json.dumps(SCHEMA), "--tools", ""]
    if model:
        cmd += ["--model", model]
    if max_budget_usd:
        cmd += ["--max-budget-usd", str(max_budget_usd)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None, None, f"claude exited {result.returncode}: {result.stderr[:500]}"
    try:
        response = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        return None, None, f"could not parse claude JSON output: {e}: {result.stdout[:500]}"
    structured = response.get("structured_output")
    if structured is None:
        return None, None, f"no structured_output in response: {result.stdout[:500]}"
    cost = response.get("total_cost_usd")
    return structured, cost, None


def build_msgstr_block(msgid, msgstr, is_nowrap):
    """Render msgid+msgstr through polib+msgcat to get gettext-correct escaping/wrapping.

    JP: polib+msgcat に通すことで gettext 純正のエスケープ/ラップ処理を得たうえで、
    msgstr 部分だけの raw テキストを返す(構造的に走査するのみで再デコードはしない)。
    """
    po = polib.POFile()
    po.metadata = {"Content-Type": "text/plain; charset=UTF-8"}
    entry = polib.POEntry(msgid=msgid, msgstr=msgstr)
    if is_nowrap:
        entry.flags = ["no-wrap"]
    po.append(entry)

    with tempfile.NamedTemporaryFile("w", suffix=".po", delete=False, encoding="utf-8") as f:
        f.write(str(po))
        tmp_path = f.name
    try:
        result = subprocess.run(
            ["msgcat", f"--width={WRAP_WIDTH}", "-o", "-", tmp_path],
            capture_output=True, text=True,
        )
    finally:
        os.unlink(tmp_path)
    if result.returncode != 0:
        raise RuntimeError(f"msgcat failed: {result.stderr}")

    out_text = result.stdout
    out_blocks = split_blocks(out_text)
    if len(out_blocks) != 2:
        raise RuntimeError(f"unexpected msgcat output shape ({len(out_blocks)} blocks)")
    s, e = out_blocks[1]
    struct = scan_block(out_text[s:e], s)
    return out_text[struct["msgstr_start"]:struct["block_end"]]


def fuzzy_flags_line(existing_flags):
    """Build a flags line that adds "fuzzy" (first) to whatever flags already existed."""
    flags = ["fuzzy"] + [f for f in existing_flags if f != "fuzzy"]
    return "#, " + ", ".join(flags) + "\n"


def apply_replacements(text, replacements):
    replacements = sorted(replacements, key=lambda r: r[0])
    out = []
    pos = 0
    for start, end, new_text in replacements:
        assert start >= pos, "overlapping replacement spans"
        out.append(text[pos:start])
        out.append(new_text)
        pos = end
    out.append(text[pos:])
    return "".join(out)


def cmd_dry_run(args, text, entries, targets, preamble, command_meta):
    print(f"{len(targets)} target entries (untranslated/fuzzy) selected out of {len(entries)} total.")
    few_shot = sample_few_shot(entries, args.few_shot)
    for batch_no, batch in enumerate(build_batches(targets, args.batch_size), 1):
        prompt = build_prompt(preamble, few_shot, batch, command_meta)
        print(f"\n===== batch {batch_no} ({len(batch)} entries) =====")
        print(prompt)
        print(f"----- schema -----\n{json.dumps(SCHEMA, ensure_ascii=False, indent=2)}")
    return 0


def apply_structured_batch(structured, batch, by_index):
    """AI の1バッチ分の応答を、置換範囲リストへ変換する。

    JP: `translations` 配列を検証しながら msgstr のサージカル置換を組み立てる。
    新規に翻訳した(元は未翻訳だった)エントリは fuzzy 化し、元々 fuzzy だった
    エントリはそのまま fuzzy を維持する(flags・previous-msgid は変更しない)。
    いずれの場合も、po-mode/info/html 上で該当範囲を検索できるよう
    AI 翻訳者コメントを付与する。戻り値は (replacements, translated_ids, skipped_ids)。
    """
    replacements = []
    translated_ids = []
    skipped_ids = []
    got_ids = set()

    for item in structured.get("translations", []):
        idx = item.get("id")
        msgstr = item.get("msgstr")
        if idx not in by_index or msgstr is None:
            continue
        got_ids.add(idx)
        entry = by_index[idx]
        original_msgid = entry.po_entry.msgid
        if original_msgid.count("\n") != msgstr.count("\n") or original_msgid.count("\t") != msgstr.count("\t"):
            print(f"entry #{idx}: \\n/\\t count mismatch, skipping")
            skipped_ids.append(idx)
            continue
        try:
            msgstr_block = build_msgstr_block(original_msgid, msgstr, entry.is_nowrap)
        except RuntimeError as e:
            print(f"entry #{idx}: failed to render replacement, skipping: {e}")
            skipped_ids.append(idx)
            continue

        s = entry.struct
        replacements.append((s["msgstr_start"], s["block_end"], msgstr_block))

        block_start = entry.block_span[0]
        replacements.append((block_start, block_start, f"# {AI_MARKER}\n"))
        if entry.is_untranslated:
            if s["flags_start"] is not None:
                replacements.append(
                    (s["flags_start"], s["flags_end"], fuzzy_flags_line(entry.po_entry.flags))
                )
            else:
                replacements.append((s["msgid_start"], s["msgid_start"], "#, fuzzy\n"))
        translated_ids.append(idx)

    missing = [e.index for e in batch if e.index not in got_ids]
    if missing:
        print(f"AI response missing ids {missing}, left untouched")
        skipped_ids.extend(missing)

    return replacements, translated_ids, skipped_ids


def write_po_file(po_path, text, replacements):
    """置換リストを適用し、msgfmt -c 検証を通してからアトミックに書き込む。"""
    new_text = apply_replacements(text, replacements)

    po_path = Path(po_path).resolve()
    dir_ = po_path.parent
    fd, tmp_path = tempfile.mkstemp(dir=dir_, suffix=".po.tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(new_text)
        check = subprocess.run(["msgfmt", "-c", "-o", os.devnull, tmp_path], capture_output=True, text=True)
        if check.returncode != 0:
            raise RuntimeError(f"msgfmt -c failed, aborting:\n{check.stderr}")
        os.replace(tmp_path, po_path)
    except Exception:
        os.unlink(tmp_path)
        raise
    return new_text


def cmd_translate(args, text, entries, targets, preamble, command_meta):
    if not targets:
        print("nothing to translate.")
        return 0

    few_shot = sample_few_shot(entries, args.few_shot)
    by_index = {e.index: e for e in targets}
    replacements = []
    translated_count = 0
    skipped = []
    total_cost = 0.0
    batch_count = 0

    for batch in build_batches(targets, args.batch_size):
        batch_count += 1
        prompt = build_prompt(preamble, few_shot, batch, command_meta)
        structured, cost, error = call_claude(prompt, args.model, args.max_budget_usd)
        if cost:
            total_cost += cost
        if error:
            print(f"batch {batch_count} failed, skipping ({len(batch)} entries): {error}")
            skipped.extend(e.index for e in batch)
            continue

        batch_replacements, translated_ids, skipped_ids = apply_structured_batch(structured, batch, by_index)
        replacements.extend(batch_replacements)
        translated_count += len(translated_ids)
        skipped.extend(skipped_ids)

    if not replacements:
        print("no successful translations; file left unchanged.")
        return 1

    write_po_file(args.po_file, text, replacements)

    print(f"\ntranslated {translated_count} entries, skipped {len(skipped)}, "
          f"{batch_count} batch(es), total_cost_usd={total_cost:.4f}")
    if skipped:
        print(f"skipped entry ids: {sorted(set(skipped))}")
    return 0


def cmd_manual_export(args, text, entries, targets, preamble, command_meta):
    """先頭バッチ1個分のプロンプトをファイルへ書き出す(claude は呼ばない)。"""
    batch = next(build_batches(targets, args.batch_size), None)
    if batch is None:
        print("nothing to translate.")
        return 0

    few_shot = sample_few_shot(entries, args.few_shot)
    prompt = build_prompt(preamble, few_shot, batch, command_meta, include_schema_text=True)

    paths = session_paths(args.po_file)
    paths["prompt"].write_text(prompt, encoding="utf-8")
    paths["response"].write_text("", encoding="utf-8")
    session = {
        "po_file": str(Path(args.po_file).resolve()),
        "po_sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        "entry_ids": [e.index for e in batch],
    }
    paths["session"].write_text(json.dumps(session, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"MANUAL_PROMPT_FILE={paths['prompt']}")
    print(f"MANUAL_SESSION_FILE={paths['session']}")
    print(f"MANUAL_RESPONSE_FILE={paths['response']}")
    print(f"\n{len(batch)} 件分のプロンプトを書き出しました。prompt.txt の内容を AI チャットに貼り付け、"
          "返ってきた JSON を response.json に保存してから --manual-apply を実行してください。")
    return 0


def cmd_manual_paths(args):
    """既存セッションのファイルパスを問い合わせるだけで、何も書き込まない。

    JP: session_paths() はディレクトリ作成以外に副作用が無いため、--manual-export を
    まだ一度も実行していなくても安全に呼べる。Emacs 側が「前回 export した際の
    バッファローカル変数」に頼らず、po ファイルのパスから毎回パスを再導出できるように
    するためのクエリ専用コマンド。
    """
    paths = session_paths(args.po_file)
    print(f"MANUAL_PROMPT_FILE={paths['prompt']}")
    print(f"MANUAL_SESSION_FILE={paths['session']}")
    print(f"MANUAL_RESPONSE_FILE={paths['response']}")
    return 0


def cmd_manual_apply(args):
    """--manual-export したセッションの response.json を読み、po ファイルへ反映する。"""
    paths = session_paths(args.po_file)
    if not paths["session"].exists():
        sys.exit(f"session file not found: {paths['session']} (先に --manual-export を実行してください)")
    session = json.loads(paths["session"].read_text(encoding="utf-8"))

    po_path = Path(args.po_file).resolve()
    if session.get("po_file") != str(po_path):
        sys.exit(f"session file is for a different po file ({session.get('po_file')}), aborting")

    assert_not_relnotes(po_path)
    text, entries = load_entries(po_path)
    problems = cross_check(text, entries, po_path)
    if problems:
        for p in problems:
            print(f"FAIL {p}")
        sys.exit("parser cross-check failed, aborting")

    current_sha256 = hashlib.sha256(text.encode("utf-8")).hexdigest()
    if current_sha256 != session.get("po_sha256"):
        sys.exit(
            "po file has changed since --manual-export was run; "
            "re-run --manual-export and try again."
        )

    if not paths["response"].exists():
        sys.exit(f"response file not found: {paths['response']}")
    response_text = paths["response"].read_text(encoding="utf-8").strip()
    if not response_text:
        sys.exit(f"response file is empty: {paths['response']}")
    try:
        structured = json.loads(response_text)
    except json.JSONDecodeError as e:
        sys.exit(
            f"could not parse {paths['response']} as JSON: {e}\n"
            "AI チャットの回答から JSON 部分だけを抜き出して保存し直してください。"
        )
    if not isinstance(structured, dict) or not isinstance(structured.get("translations"), list):
        sys.exit(f'{paths["response"]}: expected an object with a "translations" array')

    entry_ids = session.get("entry_ids", [])
    by_index = {e.index: e for e in entries if e.index in entry_ids}
    batch = [by_index[i] for i in entry_ids if i in by_index]
    if len(batch) != len(entry_ids):
        sys.exit("some entry ids from the session no longer exist in the po file, aborting")

    replacements, translated_ids, skipped_ids = apply_structured_batch(structured, batch, by_index)
    if not replacements:
        print("no successful translations; file left unchanged.")
        return 1

    write_po_file(po_path, text, replacements)

    print(f"translated {len(translated_ids)} entries, skipped {len(skipped_ids)}")
    if skipped_ids:
        print(f"skipped entry ids: {sorted(set(skipped_ids))}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("po_file", nargs="?", help="path to a Documentation-po/*.po file")
    parser.add_argument("--selftest", action="store_true",
                         help="cross-check parser against polib over the whole corpus, no API calls")
    parser.add_argument("--dry-run", action="store_true",
                         help="print prompts/batches without calling claude")
    parser.add_argument("--manual-export", action="store_true",
                         help="write the first batch's prompt to a file instead of calling claude, "
                              "for pasting into a free AI chat (see MANUAL_*_FILE= output)")
    parser.add_argument("--manual-apply", action="store_true",
                         help="apply a previously --manual-export'd batch from its response.json")
    parser.add_argument("--manual-paths", action="store_true",
                         help="print MANUAL_*_FILE= paths for this po file without exporting "
                              "anything (query only, safe to call anytime)")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--only-untranslated", action="store_true")
    group.add_argument("--only-fuzzy", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--batch-size", type=int, default=30)
    parser.add_argument("--few-shot", type=int, default=5)
    parser.add_argument("--model", default=None)
    parser.add_argument("--max-budget-usd", type=float, default=1.0)
    args = parser.parse_args()

    if args.selftest:
        return cmd_selftest(args)

    if not args.po_file:
        parser.error("po_file is required unless --selftest is given")

    if args.manual_apply:
        return cmd_manual_apply(args)
    if args.manual_paths:
        return cmd_manual_paths(args)

    assert_not_relnotes(args.po_file)
    text, entries = load_entries(args.po_file)
    problems = cross_check(text, entries, args.po_file)
    if problems:
        for p in problems:
            print(f"FAIL {p}")
        sys.exit("parser cross-check failed, aborting")

    targets = select_targets(entries, args.only_untranslated, args.only_fuzzy, args.limit)
    preamble = PROMPT_FILE.read_text(encoding="utf-8")
    command_meta = command_meta_for_path(args.po_file)

    if args.dry_run:
        return cmd_dry_run(args, text, entries, targets, preamble, command_meta)
    if args.manual_export:
        return cmd_manual_export(args, text, entries, targets, preamble, command_meta)
    return cmd_translate(args, text, entries, targets, preamble, command_meta)


if __name__ == "__main__":
    sys.exit(main())
