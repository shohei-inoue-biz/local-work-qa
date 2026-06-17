#!/usr/bin/env bash
# search.sh - records/ を横断してキーワード・タグで検索する

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDS_DIR="$ROOT_DIR/records"

usage() {
  cat <<EOF
使い方:
  $(basename "$0") [オプション] <キーワード>

オプション:
  -t, --tag <tag>       タグで絞り込む（例: docker, ci）
  -p, --project <name>  プロジェクト名で絞り込む
  -s, --status <status> ステータスで絞り込む（resolved / unresolved / workaround）
  -h, --help            このヘルプを表示

例:
  $(basename "$0") docker
  $(basename "$0") -t ci build
  $(basename "$0") --status unresolved
  $(basename "$0") -p sample-repo authentication
EOF
  exit 0
}

KEYWORD=""
TAG_FILTER=""
PROJECT_FILTER=""
STATUS_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)      TAG_FILTER="$2";     shift 2 ;;
    -p|--project)  PROJECT_FILTER="$2"; shift 2 ;;
    -s|--status)   STATUS_FILTER="$2";  shift 2 ;;
    -h|--help)     usage ;;
    -*) echo "不明なオプション: $1" >&2; usage ;;
    *)  KEYWORD="$1"; shift ;;
  esac
done

if [[ -z "$KEYWORD" && -z "$TAG_FILTER" && -z "$PROJECT_FILTER" && -z "$STATUS_FILTER" ]]; then
  usage
fi

FOUND=0

while IFS= read -r file; do
  # プロジェクトフィルタ
  if [[ -n "$PROJECT_FILTER" ]]; then
    project=$(grep -m1 '^project:' "$file" | sed 's/project: *//' | tr -d '\r')
    [[ "$project" != *"$PROJECT_FILTER"* ]] && continue
  fi

  # タグフィルタ
  if [[ -n "$TAG_FILTER" ]]; then
    tags=$(grep -m1 '^tags:' "$file" | sed 's/tags: *//' | tr -d '\r')
    [[ "$tags" != *"$TAG_FILTER"* ]] && continue
  fi

  # ステータスフィルタ
  if [[ -n "$STATUS_FILTER" ]]; then
    status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
    [[ "$status" != "$STATUS_FILTER" ]] && continue
  fi

  # キーワード検索（ファイル全体）
  if [[ -n "$KEYWORD" ]]; then
    grep -qi "$KEYWORD" "$file" 2>/dev/null || continue
  fi

  # マッチしたファイルの情報を表示
  date=$(grep -m1 '^date:' "$file" | sed 's/date: *//' | tr -d '\r')
  project=$(grep -m1 '^project:' "$file" | sed 's/project: *//' | tr -d '\r')
  status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
  tags=$(grep -m1 '^tags:' "$file" | sed 's/tags: *//' | tr -d '\r')
  title=$(grep -m1 '^# ' "$file" | sed 's/^# //' | tr -d '\r')
  rel_path="${file#$RECORDS_DIR/}"

  echo "---"
  echo "📄 $title"
  echo "   プロジェクト: $project  |  日付: $date  |  ステータス: $status"
  echo "   タグ: $tags"
  echo "   パス: records/$rel_path"

  # キーワードにマッチした行を抜粋表示
  if [[ -n "$KEYWORD" ]]; then
    echo "   --- マッチ箇所 ---"
    grep -in "$KEYWORD" "$file" | head -3 | while IFS= read -r line; do
      echo "   $line"
    done
  fi

  FOUND=$((FOUND + 1))
done < <(find "$RECORDS_DIR" -name '*.md' ! -name '_index.md' | sort)

echo ""
if [[ $FOUND -eq 0 ]]; then
  echo "❌ 該当する記録が見つかりませんでした。"
else
  echo "✅ $FOUND 件の記録が見つかりました。"
fi
