#!/usr/bin/env bash
# auto-record.sh - コンテキストを収集し、Copilot CLI で問題記録を自動生成・保存する
# bash 3.x (macOS デフォルト) 互換
#
# 使い方:
#   ./scripts/auto-record.sh                    # コンテキスト収集から記録生成まで全自動
#   ./scripts/auto-record.sh contexts/2026-06-17-1300.md  # 既存のコンテキストを使って生成
#   ./scripts/auto-record.sh --dry-run          # プロンプトだけ生成して確認（AI呼び出しなし）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$ROOT_DIR/templates/problem.md"

DRY_RUN=0
CONTEXT_ARG=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      cat <<EOF
使い方:
  $(basename "$0") [オプション] [コンテキストファイル]

オプション:
  --dry-run    プロンプトファイルだけ生成して AI は呼び出さない
  -h, --help   このヘルプを表示

引数を省略すると collect-context.sh を自動実行します。
EOF
      exit 0
      ;;
    -*) echo "不明なオプション: $arg" >&2; exit 1 ;;
    *)  CONTEXT_ARG="$arg" ;;
  esac
done

# ========================================
# コンテキストファイルの準備
# ========================================
if [[ -n "$CONTEXT_ARG" ]]; then
  CONTEXT_FILE="$ROOT_DIR/$CONTEXT_ARG"
  [[ ! -f "$CONTEXT_FILE" ]] && CONTEXT_FILE="$CONTEXT_ARG"
  [[ ! -f "$CONTEXT_FILE" ]] && { echo "❌ ファイルが見つかりません: $CONTEXT_ARG" >&2; exit 1; }
else
  echo "📥 コンテキストを収集します..."
  bash "$SCRIPT_DIR/collect-context.sh"
  CONTEXT_FILE=$(find "$ROOT_DIR/contexts" -name '*.md' ! -name '*-prompt*' | sort | tail -1)
fi

echo ""
echo "📄 コンテキストファイル: $CONTEXT_FILE"

# ========================================
# プロンプト生成
# ========================================
PROMPT_FILE="${CONTEXT_FILE%.md}-prompt.txt"

cat > "$PROMPT_FILE" <<PROMPT
以下の「作業コンテキスト」を分析して、今日の作業で直面した問題・詰まりポイントを特定し、
テンプレートの形式に従って問題記録ファイルを作成・保存してください。

## 指示

1. コンテキストから「何をしようとしていたか」「どこで詰まったか」「どう解決したか」を読み取る
2. 複数の問題がある場合は最も重要なものを1件選ぶ
3. テンプレートのすべてのフィールドを埋める（不明な場合は推測して [要確認] を付ける）
4. 以下のパスにファイルを保存する:
   records/{project}/{task-slug}/$(date +%Y-%m-%d)-{problem-slug}.md
   （project と task は frontmatter の値から決定し、slug はハイフン区切り小文字英数字）
5. 保存後に ./scripts/update-index.sh を実行してインデックスを更新する

## テンプレート

$(cat "$TEMPLATE")

---

## 作業コンテキスト

$(cat "$CONTEXT_FILE")
PROMPT

echo "✅ プロンプトを生成しました: $PROMPT_FILE"

# ========================================
# Copilot CLI で自動生成
# ========================================
if [[ $DRY_RUN -eq 1 ]]; then
  echo ""
  echo "【dry-run モード】AI呼び出しをスキップしました。"
  echo "プロンプトを確認: cat $PROMPT_FILE"
  exit 0
fi

COPILOT_BIN=$(which copilot 2>/dev/null || echo "")
if [[ -z "$COPILOT_BIN" ]]; then
  echo ""
  echo "⚠️  copilot コマンドが見つかりませんでした。"
  echo "手動でプロンプトを Copilot CLI に渡してください:"
  echo ""
  echo "  「$PROMPT_FILE を読んで問題記録を生成・保存して」"
  exit 0
fi

echo ""
echo "🤖 Copilot CLI で記録を生成しています..."
echo "   （--allow-all で自動実行します）"
echo ""

PROMPT_CONTENT=$(cat "$PROMPT_FILE")

"$COPILOT_BIN" \
  --allow-all \
  --add-dir "$ROOT_DIR" \
  -p "$PROMPT_CONTENT"

echo ""
echo "✅ 完了。records/ に記録が保存されているか確認してください:"
echo "   ls records/"
