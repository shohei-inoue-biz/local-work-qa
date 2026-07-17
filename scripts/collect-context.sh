#!/usr/bin/env bash
# collect-context.sh - 今日の作業コンテキストを複数ソースから収集してファイルに出力する
# bash 3.x (macOS デフォルト) 互換
#
# 収集ソース:
#   - zsh コマンド履歴（直近200件 ※タイムスタンプなしのため近似）
#   - Chrome ブラウザ検索履歴（今日分）
#   - Copilot CLI セッションログ（今日分）
#   - Codex CLI ログ（インストール済みの場合）
#   - Gemini CLI ログ（インストール済みの場合）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONTEXTS_DIR="$ROOT_DIR/contexts"
mkdir -p "$CONTEXTS_DIR"

TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H%M)
OUTPUT_FILE="$CONTEXTS_DIR/${TODAY}-${HOUR}.md"

# Chrome History DBのパス
CHROME_HISTORY="$HOME/Library/Application Support/Google/Chrome/Default/History"
# Copilot CLI session store
COPILOT_DB="$HOME/.copilot/session-store.db"

echo "🔍 コンテキストを収集しています..."
echo ""

# ========================================
# ヘッダー
# ========================================
cat > "$OUTPUT_FILE" <<HEADER
# 作業コンテキスト: $TODAY

収集日時: $(date "+%Y-%m-%d %H:%M:%S")

---

HEADER

# ========================================
# 1. zsh コマンド履歴（直近200件）
# ========================================
echo "## 1. シェルコマンド履歴（直近200件・近似）" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [[ -f ~/.zsh_history ]]; then
  echo '```' >> "$OUTPUT_FILE"
  # EXTENDED_HISTORY形式（: timestamp:elapsed;cmd）かノーマルか判定
  if grep -q '^: [0-9]' ~/.zsh_history 2>/dev/null; then
    # タイムスタンプあり → 今日分をフィルタ
    TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s" 2>/dev/null || date -d "$TODAY" "+%s" 2>/dev/null || echo 0)
    grep '^: [0-9]' ~/.zsh_history | awk -v epoch="$TODAY_EPOCH" -F'[;:]' '{
      if ($2 >= epoch) { for(i=3;i<=NF;i++) printf "%s%s", (i>3?":":""), $i; print "" }
    }' | tail -200 >> "$OUTPUT_FILE"
  else
    # タイムスタンプなし → 末尾200件
    tail -200 ~/.zsh_history >> "$OUTPUT_FILE"
  fi
  echo '```' >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "✅ zsh 履歴: 収集完了"
else
  echo "*zsh 履歴ファイルが見つかりませんでした*" >> "$OUTPUT_FILE"
  echo "⚠️  zsh 履歴: 見つかりません"
fi

echo "" >> "$OUTPUT_FILE"

# ========================================
# 2. Chrome ブラウザ検索履歴（今日分）
# ========================================
echo "## 2. Chrome 検索履歴（今日）" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [[ -f "$CHROME_HISTORY" ]]; then
  TMP_CHROME=$(mktemp /tmp/chrome_context_XXXXXX.db)
  trap "rm -f $TMP_CHROME" EXIT
  cp "$CHROME_HISTORY" "$TMP_CHROME"

  # Chrome の時刻は WebKit epoch (1601-01-01) からのマイクロ秒
  # 今日の00:00:00 UTC を WebKit epoch マイクロ秒に変換
  TODAY_WEBKIT=$(python3 -c "
import datetime, calendar
dt = datetime.datetime.strptime('$TODAY 00:00:00', '%Y-%m-%d %H:%M:%S')
unix_epoch = int(calendar.timegm(dt.timetuple()))
webkit_epoch = unix_epoch * 1000000 + 11644473600000000
print(webkit_epoch)
" 2>/dev/null || echo 0)

  SEARCH_RESULTS=$(sqlite3 "$TMP_CHROME" \
    "SELECT DISTINCT kst.term
     FROM keyword_search_terms kst
     JOIN urls u ON kst.url_id = u.id
     JOIN visits v ON v.url = u.id
     WHERE v.visit_time > $TODAY_WEBKIT
     ORDER BY v.visit_time ASC;" 2>/dev/null || echo "")

  URL_RESULTS=$(sqlite3 "$TMP_CHROME" \
    "SELECT DISTINCT u.title, u.url
     FROM urls u
     JOIN visits v ON v.url = u.id
     WHERE v.visit_time > $TODAY_WEBKIT
       AND u.url NOT LIKE 'chrome%'
       AND u.url NOT LIKE 'about:%'
     ORDER BY v.visit_time ASC
     LIMIT 100;" 2>/dev/null || echo "")

  rm -f "$TMP_CHROME"

  if [[ -n "$SEARCH_RESULTS" ]]; then
    echo "### 検索クエリ" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "$SEARCH_RESULTS" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  fi

  if [[ -n "$URL_RESULTS" ]]; then
    echo "### 訪問ページ（タイトル / URL）" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "$URL_RESULTS" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  fi

  echo "✅ Chrome 履歴: 収集完了"
else
  echo "*Chrome 履歴ファイルが見つかりませんでした*" >> "$OUTPUT_FILE"
  echo "⚠️  Chrome 履歴: 見つかりません ($CHROME_HISTORY)"
fi

echo "" >> "$OUTPUT_FILE"

# ========================================
# 3. Copilot CLI セッションログ（今日分）
# ========================================
echo "## 3. Copilot CLI セッション（今日）" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [[ -f "$COPILOT_DB" ]]; then
  COPILOT_TURNS=$(sqlite3 "$COPILOT_DB" \
    "SELECT 'USER: ' || substr(user_message, 1, 500) || char(10) ||
            'ASSISTANT: ' || substr(assistant_response, 1, 500)
     FROM turns
     WHERE timestamp >= '${TODAY}T00:00:00'
     ORDER BY timestamp ASC;" 2>/dev/null || echo "")

  if [[ -n "$COPILOT_TURNS" ]]; then
    echo '```' >> "$OUTPUT_FILE"
    echo "$COPILOT_TURNS" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
  else
    echo "*今日のセッションデータはありません*" >> "$OUTPUT_FILE"
  fi
  echo "✅ Copilot CLI: 収集完了"
else
  echo "*Copilot CLI セッションDBが見つかりませんでした*" >> "$OUTPUT_FILE"
  echo "⚠️  Copilot CLI: DBが見つかりません"
fi

echo "" >> "$OUTPUT_FILE"

# ========================================
# 4. Codex CLI セッションログ（今日分）
# ========================================
# Codex CLI は ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl に
# セッションを JSONL 形式で記録する（ログディレクトリではない）。
echo "## 4. Codex CLI セッション（今日）" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

CODEX_SESSIONS_DIR="$HOME/.codex/sessions/$(date +%Y)/$(date +%m)/$(date +%d)"

if [[ -d "$CODEX_SESSIONS_DIR" ]] && ls "$CODEX_SESSIONS_DIR"/rollout-*.jsonl >/dev/null 2>&1; then
  CODEX_TURNS=$(python3 - "$CODEX_SESSIONS_DIR" "$ROOT_DIR" <<'PYEOF'
import json
import sys
from pathlib import Path

sessions_dir = Path(sys.argv[1])
root_dir = Path(sys.argv[2]).resolve()

lines_out = []
for jsonl_path in sorted(sessions_dir.glob("rollout-*.jsonl")):
    cwd = None
    turns = []
    try:
        with jsonl_path.open(encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                entry_type = entry.get("type")
                payload = entry.get("payload", {})
                if entry_type == "session_meta":
                    cwd = payload.get("cwd")
                    continue
                if entry_type != "event_msg":
                    continue
                if payload.get("type") == "user_message":
                    msg = (payload.get("message") or "").strip()
                    if msg:
                        turns.append(("USER", msg[:500]))
                elif payload.get("type") == "agent_message":
                    msg = (payload.get("message") or "").strip()
                    if msg:
                        turns.append(("ASSISTANT", msg[:500]))
    except OSError:
        continue

    if not turns:
        continue

    # 対象リポジトリ配下で実行されたセッションのみ対象にする
    if cwd:
        try:
            if root_dir not in Path(cwd).resolve().parents and Path(cwd).resolve() != root_dir:
                continue
        except OSError:
            pass

    lines_out.append(f"### {jsonl_path.name} (cwd: {cwd})")
    for role, text in turns:
        lines_out.append(f"{role}: {text}")
    lines_out.append("")

print("\n".join(lines_out))
PYEOF
)

  if [[ -n "$CODEX_TURNS" ]]; then
    echo '```' >> "$OUTPUT_FILE"
    echo "$CODEX_TURNS" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "✅ Codex CLI: 収集完了"
  else
    echo "*今日のセッションデータ（このリポジトリ配下）はありません*" >> "$OUTPUT_FILE"
    echo "⚠️  Codex CLI: 今日のセッションなし（このリポジトリ配下）"
  fi
else
  echo "*Codex CLI のセッションログが見つかりませんでした（$CODEX_SESSIONS_DIR）*" >> "$OUTPUT_FILE"
  echo "⚠️  Codex CLI: セッションログが見つかりません"
fi

echo "" >> "$OUTPUT_FILE"

# ========================================
# 5. Gemini CLI ログ（インストール済みの場合）
# ========================================
echo "## 5. Gemini CLI ログ" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

GEMINI_LOG_DIRS=(
  "$HOME/.gemini/logs"
  "$HOME/.config/gemini/logs"
  "$HOME/Library/Application Support/google-gemini-cli/logs"
  "$HOME/Library/Logs/gemini-cli"
)
GEMINI_FOUND=0
for dir in "${GEMINI_LOG_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "### $dir" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    find "$dir" -name "*.log" -mtime -1 -exec tail -100 {} \; 2>/dev/null >> "$OUTPUT_FILE" || true
    echo '```' >> "$OUTPUT_FILE"
    GEMINI_FOUND=1
    echo "✅ Gemini CLI: 収集完了"
    break
  fi
done
if [[ $GEMINI_FOUND -eq 0 ]]; then
  echo "*Gemini CLI がインストールされていないか、ログが見つかりませんでした*" >> "$OUTPUT_FILE"
  echo "⚠️  Gemini CLI: 未インストール（スキップ）"
fi

echo "" >> "$OUTPUT_FILE"

# ========================================
# フッター
# ========================================
cat >> "$OUTPUT_FILE" <<FOOTER
---

## メモ（手動追記欄）

<!-- 上記ログに現れない補足情報、詰まったポイント、感じたことなどを自由に記入 -->

FOOTER

echo ""
echo "✅ コンテキスト収集完了: $OUTPUT_FILE"
echo ""
echo "次のステップ: auto-record.sh を実行して記録を自動生成"
echo "  ./scripts/auto-record.sh $OUTPUT_FILE"
