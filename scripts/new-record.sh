#!/usr/bin/env bash
# new-record.sh - 新規問題記録を対話形式で作成する

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$ROOT_DIR/templates/problem.md"
RECORDS_DIR="$ROOT_DIR/records"

# --- 入力受付 ---
read -rp "リポジトリ/プロジェクト名: " PROJECT
read -rp "タスク名（例: setup-ci, add-auth）: " TASK
read -rp "問題タイトル（一文）: " TITLE
read -rp "タグ（カンマ区切り、例: build,ci,docker）: " TAGS_RAW
read -rp "使用したAIエージェント（例: Copilot CLI）: " AGENT

DATE=$(date +%Y-%m-%d)
TAGS=$(echo "$TAGS_RAW" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | awk '{printf "\"%s\", ", $0}' | sed 's/, $//')

# スラグ生成（スペース→ハイフン、小文字化）
TASK_SLUG=$(echo "$TASK" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
TITLE_SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | cut -c1-50)

# ディレクトリ作成
TARGET_DIR="$RECORDS_DIR/$PROJECT/$TASK_SLUG"
mkdir -p "$TARGET_DIR"

# インデックスファイル生成（なければ）
REPO_INDEX="$RECORDS_DIR/$PROJECT/_index.md"
if [ ! -f "$REPO_INDEX" ]; then
  cat > "$REPO_INDEX" <<EOF
# $PROJECT の記録

| 日付 | タスク | 問題タイトル | ステータス | タグ |
|---|---|---|---|---|
EOF
fi

# ファイル生成
OUTPUT_FILE="$TARGET_DIR/${DATE}-${TITLE_SLUG}.md"
if [ -f "$OUTPUT_FILE" ]; then
  echo "⚠️  既に存在します: $OUTPUT_FILE"
  exit 1
fi

sed \
  -e "s/YYYY-MM-DD/$DATE/g" \
  -e "s/リポジトリ・プロジェクト名/$PROJECT/g" \
  -e "s/タスク名（何をしようとしていたか）/$TASK/g" \
  -e "s/\[tag1, tag2\]/[$TAGS]/g" \
  -e "s/\[Copilot CLI, GitHub Copilot, etc.\]/[$AGENT]/g" \
  -e "s/\[問題タイトル：一文で表す\]/$TITLE/g" \
  "$TEMPLATE" > "$OUTPUT_FILE"

echo ""
echo "✅ 記録を作成しました: $OUTPUT_FILE"
echo ""
echo "エディタで開いて内容を記入してください:"
echo "  \$EDITOR $OUTPUT_FILE"

# グローバルインデックスに追記
echo "| $DATE | $PROJECT | $TASK | $TITLE | unresolved | $TAGS_RAW |" >> "$RECORDS_DIR/_index.md"
echo "| $DATE | $TASK | $TITLE | unresolved | $TAGS_RAW |" >> "$REPO_INDEX"
