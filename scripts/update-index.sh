#!/usr/bin/env bash
# update-index.sh - records/ 配下のmdファイルを走査してインデックスを再生成する
# bash 3.x (macOS デフォルト) 互換

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDS_DIR="$ROOT_DIR/records"
GLOBAL_INDEX="$RECORDS_DIR/_index.md"
TMP_ROWS=$(mktemp)

# グローバルインデックスのヘッダー
cat > "$GLOBAL_INDEX" <<'EOF'
# 記録インデックス

| 日付 | プロジェクト | タスク | 問題タイトル | ステータス | タグ |
|---|---|---|---|---|---|
EOF

# 全記録ファイルを走査（sort で日付順）
find "$RECORDS_DIR" -name '*.md' ! -name '_index.md' | sort | while IFS= read -r file; do
  date=$(grep -m1 '^date:' "$file" | sed 's/date: *//' | tr -d '\r')
  project=$(grep -m1 '^project:' "$file" | sed 's/project: *//' | tr -d '\r')
  task=$(grep -m1 '^task:' "$file" | sed 's/task: *//' | tr -d '\r')
  status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
  tags=$(grep -m1 '^tags:' "$file" | sed 's/tags: *//' | tr -d '\r')
  title=$(grep -m1 '^# ' "$file" | sed 's/^# //' | tr -d '\r')
  rel_path="${file#$RECORDS_DIR/}"

  echo "| $date | $project | $task | [$title]($rel_path) | $status | $tags |" >> "$GLOBAL_INDEX"
  echo "$project	| $date | $task | [$title]($rel_path) | $status | $tags |" >> "$TMP_ROWS"
done

echo "" >> "$GLOBAL_INDEX"
echo "---" >> "$GLOBAL_INDEX"
echo "" >> "$GLOBAL_INDEX"
echo "## プロジェクト別" >> "$GLOBAL_INDEX"

# プロジェクト別にグループ化して出力
cut -f1 "$TMP_ROWS" | sort -u | while IFS= read -r project; do
  echo "" >> "$GLOBAL_INDEX"
  echo "### $project" >> "$GLOBAL_INDEX"
  echo "" >> "$GLOBAL_INDEX"
  echo "| 日付 | タスク | 問題タイトル | ステータス | タグ |" >> "$GLOBAL_INDEX"
  echo "|---|---|---|---|---|" >> "$GLOBAL_INDEX"
  grep "^${project}	" "$TMP_ROWS" | cut -f2- >> "$GLOBAL_INDEX"
done

# プロジェクト別 _index.md を再生成
cut -f1 "$TMP_ROWS" | sort -u | while IFS= read -r project; do
  repo_index="$RECORDS_DIR/$project/_index.md"
  cat > "$repo_index" <<HEADER
# $project の記録

| 日付 | タスク | 問題タイトル | ステータス | タグ |
|---|---|---|---|---|
HEADER
  grep "^${project}	" "$TMP_ROWS" | cut -f2- >> "$repo_index"
done

rm -f "$TMP_ROWS"
echo ""
echo "✅ インデックスを更新しました: $GLOBAL_INDEX"
echo "✅ プロジェクト別インデックスも更新しました"
