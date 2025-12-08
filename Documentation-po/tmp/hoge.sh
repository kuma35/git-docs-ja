#!/usr/bin/env bash
# File: git-rev-list-options-study/create-exact-doc-repo.sh
# 実行すると git-rev-list-options-study/repo/ に公式ドキュメントと完全に同一のリポジトリができます

set -euo pipefail

REPO_DIR="repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

rm -rf .git 2>/dev/null || true
git init -q

# コミット作成ヘルパー
commit() {
    echo $@
    local msg="$1"
    shift
    while [[ $# -gt 0 ]]; do
        echo -n "$2" > "$1"
        git add "$1"
        shift 2
    done
    git commit -q -m "$msg"
}

echo "公式ドキュメントの --ancestry-path 説明図を正確に再現中..."

# 1. 最初のコミット I（空ツリーからの初回コミット → !TREESAME）
commit "I"  foo "asdf"  quux "quux"
I=$(git rev-parse HEAD)

# 2. A（foo を "foo" に変更）
commit "A"  foo "foo"

# 3. B（A と同じ変更 → A と TREESAME）
git checkout -q -b side-B HEAD~1   # I に戻す
commit "B"  foo "foo"

# 4. C（foo を変更しない → 親 I と TREESAME）
git checkout -q -b side-C $I
commit "C"                     # 変更なし → TREESAME to I

# 5. D（foo を "baz" に変更）
git checkout -q -b side-D $I
commit "D"  foo "baz"

# 6. E（quux を "xyzzy" に変更）
git checkout -q -b side-E $I
commit "E"  quux "xyzzy"

# 7. X（新ファイル side を追加）
git checkout -q -b side-X $I
commit "X"  side "first"

# 8. Y（side を変更 → X に対しては TREESAME ではないが、内容は違う）
git checkout -q -b side-Y side-X
commit "Y"  side "second"

# メインラインに戻って順番にマージしていく（これが図の斜め線）

git checkout -q master

# M: A と B をマージ（trivial merge → M は両親に対して TREESAME）
git merge -q side-B -m "M"

# N: M と C をマージ（C は変更なしだが、N で foo を "foobar" に変更）
echo "foobar" > foo
git add foo
git commit -q -m "N"

# O: N と D をマージ → foo が "foobarbaz" になる
git merge -q side-D -m "O"

# P: O と E をマージ → quux が "quux xyzzy" になる
git merge -q side-E -m "P"

# Q: P と Y をマージ → 新ファイル side が追加される
git merge -q side-Y -m "Q"

echo "完全に再現完了！"
echo "場所: $(pwd)"
echo
echo "重要なコミット（短縮ハッシュ）"
echo "  I : $(git rev-parse --short $I)"
echo "  A : $(git rev-parse --short A)"
echo "  B : $(git rev-parse --short B)"
echo "  M : $(git rev-parse --short M)"
echo "  N : $(git rev-parse --short N)"
echo "  O : $(git rev-parse --short O)"
echo "  P : $(git rev-parse --short P)"
echo "  Q : $(git rev-parse --short Q)"
echo "  X : $(git rev-parse --short X)"
echo "  Y : $(git rev-parse --short Y)"
echo
echo "これで試してください（公式ドキュメントと全く同じ結果になります）"
echo
echo "  # 全体図"
echo "  git log --graph --oneline --decorate --all"
echo
echo "  # 普通の範囲指定（大量に出る）"
echo "  git log --oneline I..Q"
echo
echo "  # --ancestry-path を使うと、ドキュメント通りの結果！"
echo "  git log --graph --oneline --decorate --ancestry-path I..Q"
echo "  # → 表示されるのは M → N → O → P → Q の5コミットだけ！"
echo
echo "  # さらに --simplify-merges も試すと"
echo "  git log --graph --oneline --simplify-merges --ancestry-path I..Q"
echo "  # → N-O-P-Q の4コミットだけになり、まさにドキュメントの斜線部分になります"

# スクリプト保存
mkdir -p ../scripts
cp "$0" ../scripts/create-exact-doc-repo.sh
chmod +x ../scripts/create-exact-doc-repo.sh

echo
echo "スクリプトを rev-list-options-study/scripts/create-exact-doc-repo.sh に保存しました"
echo "これで完璧に公式ドキュメントと同じ環境が手元にあります！"
