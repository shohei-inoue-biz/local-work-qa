#!/usr/bin/env bash
# status-update.sh - 記録ファイルのステータスを対話形式で更新する

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDS_DIR="$ROOT_DIR/records"

# 全記録ファイルをリストアップ
mapfile -t FILES < <(find "$RECORDS_DIR" -name '*.md' ! -name '_index.md' | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "❌ 記録ファイルが見つかりませんでした。"
  exit 1
fi

echo "=== ステータス更新 ==="
echo ""
echo "記録一覧:"
i=1
for file in "${FILES[@]}"; do
  title=$(grep -m1 '^# ' "$file" | sed 's/^# //' | tr -d '\r')
  status=$(grep -m1 '^status:' "$file" | sed 's/status: *//' | tr -d '\r')
  project=$(grep -m1 '^project:' "$file" | sed 's/project: *//' | tr -d '\r')
  printf "  %2d) [%-12s] %s / %s\n" "$i" "$status" "$project" "$title"
  i=$((i + 1))
done

echo ""
read -rp "更新する記録の番号を入力してください: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#FILES[@]} ]]; then
  echo "❌ 無効な番号です。"
  exit 1
fi

TARGET_FILE="${FILES[$((choice - 1))]}"
current_status=$(grep -m1 '^status:' "$TARGET_FILE" | sed 's/status: *//' | tr -d '\r')
title=$(grep -m1 '^# ' "$TARGET_FILE" | sed 's/^# //' | tr -d '\r')

echo ""
echo "対象: $title"
echo "現在のステータス: $current_status"
echo ""
echo "新しいステータスを選択してください:"
echo "  1) resolved   - 解決済み"
echo "  2) unresolved - 未解決"
echo "  3) workaround - ワークアラウンドあり"
echo ""
read -rp "番号を入力してください [1-3]: " status_choice

case "$status_choice" in
  1) NEW_STATUS="resolved" ;;
  2) NEW_STATUS="unresolved" ;;
  3) NEW_STATUS="workaround" ;;
  *)
    echo "❌ 無効な選択です。"
    exit 1
    ;;
esac

# ファイル内の status: フィールドを更新（macOS sed との互換性のため一時ファイルを使用）
TMP=$(mktemp)
sed "s/^status: .*/status: $NEW_STATUS/" "$TARGET_FILE" > "$TMP"
mv "$TMP" "$TARGET_FILE"

echo ""
echo "✅ ステータスを更新しました: $current_status → $NEW_STATUS"
echo "   ファイル: ${TARGET_FILE#$ROOT_DIR/}"
echo ""
echo "インデックスを更新するには以下を実行してください:"
echo "  ./scripts/update-index.sh"
