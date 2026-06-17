#!/usr/bin/env bash
# stats.sh - 記録の統計サマリーを表示する
# bash 3.x (macOS デフォルト) 互換

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDS_DIR="$ROOT_DIR/records"

# 全記録ファイルを収集（bash 3.x 互換）
TMP_FILES=$(mktemp)
find "$RECORDS_DIR" -name '*.md' ! -name '_index.md' | sort > "$TMP_FILES"
TOTAL=$(wc -l < "$TMP_FILES" | tr -d ' ')

if [[ "$TOTAL" -eq 0 ]]; then
  echo "記録がまだありません。"
  rm -f "$TMP_FILES"
  exit 0
fi

TMP_PROJECTS=$(mktemp)
TMP_STATUSES=$(mktemp)
TMP_TAGS=$(mktemp)

while IFS= read -r file; do
  project=$(grep -m1 '^project:' "$file" | sed 's/project: *//' | tr -d '\r')
  status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
  tags=$(grep -m1 '^tags:' "$file" | sed 's/tags: *//' | tr -d '\r' | tr -d '[]' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$')

  echo "$project" >> "$TMP_PROJECTS"
  echo "$status"  >> "$TMP_STATUSES"
  echo "$tags"    >> "$TMP_TAGS"
done < "$TMP_FILES"

echo "====================================="
echo "  📊 local-work-qa 統計サマリー"
echo "====================================="
echo ""
echo "総記録数: $TOTAL 件"
echo ""

# --- ステータス別 ---
echo "【ステータス別】"
sort "$TMP_STATUSES" | uniq -c | sort -rn | while read -r count status; do
  case "$status" in
    resolved)   label="✅ resolved  " ;;
    unresolved) label="❌ unresolved" ;;
    workaround) label="⚠️  workaround" ;;
    *)          label="   $status   " ;;
  esac
  bar=$(printf '%0.s█' $(seq 1 "$count"))
  printf "  %s  %2d 件  %s\n" "$label" "$count" "$bar"
done
echo ""

# --- プロジェクト別 ---
echo "【プロジェクト別】"
sort "$TMP_PROJECTS" | uniq -c | sort -rn | while read -r count project; do
  bar=$(printf '%0.s█' $(seq 1 "$count"))
  printf "  %-30s  %2d 件  %s\n" "$project" "$count" "$bar"
done
echo ""

# --- タグ別（上位10件）---
echo "【タグ別（上位 10）】"
sort "$TMP_TAGS" | grep -v '^$' | uniq -c | sort -rn | head -10 | while read -r count tag; do
  bar=$(printf '%0.s█' $(seq 1 "$count"))
  printf "  %-25s  %2d 件  %s\n" "$tag" "$count" "$bar"
done
echo ""

# --- 最近の記録（5件）---
echo "【最近の記録】"
while IFS= read -r file; do
  date=$(grep -m1 '^date:' "$file" | sed 's/date: *//' | tr -d '\r')
  title=$(grep -m1 '^# ' "$file" | sed 's/^# //' | tr -d '\r')
  status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
  echo "$date  $status  $title"
done < "$TMP_FILES" | sort -r | head -5 | while IFS= read -r line; do
  echo "  $line"
done
echo ""

rm -f "$TMP_FILES" "$TMP_PROJECTS" "$TMP_STATUSES" "$TMP_TAGS"
