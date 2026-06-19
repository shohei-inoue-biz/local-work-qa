# AI連携

## 概要

`auto-record.sh` は Codex CLI または Copilot CLI の非対話モードを使って、
コンテキスト収集から記録生成・保存まで全自動で行います。

```
collect-context.sh
      │ contexts/YYYY-MM-DD-HHMM.md
      ▼
プロンプト生成
      │ contexts/YYYY-MM-DD-HHMM-prompt.txt
      ▼
codex exec ... または copilot -p ...
      │
      ├─ コンテキストを分析
      ├─ 問題を特定
      ├─ records/{project}/{task}/YYYY-MM-DD-{slug}.md を作成
      └─ update-index.sh を実行
```

---

## AI CLI の選び方

`auto-record.sh` は `--agent` で使うAIを選べます。

```bash
./scripts/auto-record.sh --agent auto
./scripts/auto-record.sh --agent codex
./scripts/auto-record.sh --agent copilot
```

| 値 | 説明 |
|---|---|
| `auto` | Codex があれば Codex、なければ Copilot を使う |
| `codex` | Codex CLI を使う |
| `copilot` | Copilot CLI を使う |

## Codex CLI の非対話モード

Codex は `exec` サブコマンドで非対話実行できます。

```bash
codex exec --sandbox workspace-write --ask-for-approval never --cd "$ROOT_DIR" --add-dir "$ROOT_DIR" -
```

### 主なフラグ

| フラグ | 説明 |
|---|---|
| `exec` | Codex を非対話で実行 |
| `--sandbox workspace-write` | 作業ディレクトリへの書き込みを許可 |
| `--ask-for-approval never` | 実行中に承認プロンプトを出さない |
| `--cd <dir>` | Codex の作業ディレクトリ |
| `--add-dir <dir>` | 追加で書き込み可能にするディレクトリ |
| `-` | プロンプトを標準入力から読む |

### auto-record.sh での呼び出し方

```bash
printf '%s\n' "$PROMPT_CONTENT" | codex exec \
  --sandbox workspace-write \
  --ask-for-approval never \
  --cd "$ROOT_DIR" \
  --add-dir "$ROOT_DIR" \
  -
```

- `workspace-write`: `records/` と `contexts/` を書き込めるようにする
- `approval never`: 自動実行中に確認で止まらないようにする
- `-`: 長いプロンプトを安全に標準入力で渡す

## Copilot CLI の非対話モード

Copilot CLI は `-p/--prompt` フラグで非対話実行に対応しています。

```bash
copilot -p "プロンプトテキスト" --allow-all
```

### 主なフラグ

| フラグ | 説明 |
|---|---|
| `-p, --prompt <text>` | プロンプトを指定して非対話で実行（完了後に終了） |
| `--allow-all` | すべてのツール・パス・URL へのアクセスを許可 |
| `--allow-all-tools` | ツール（ファイル編集・シェル実行）の確認をスキップ |
| `--add-dir <dir>` | 指定ディレクトリへのファイルアクセスを許可 |
| `--output-format json` | JSONL形式で出力（スクリプト連携に便利） |

### Copilot 実行時の呼び出し方

```bash
copilot \
  --allow-all \
  --add-dir "$ROOT_DIR" \
  -p "$PROMPT_CONTENT"
```

- `--allow-all`: ファイル作成・シェル実行をすべて自動許可
- `--add-dir`: `records/` への書き込みを許可するため local-work-qa のルートを指定
- `-p`: 生成したプロンプトファイルの内容を渡す

---

## プロンプトの構造

生成されるプロンプト（`contexts/*-prompt.txt`）は以下の3部構成です：

```
1. 指示
   ├─ コンテキストを分析して問題を特定する
   ├─ テンプレートのフォーマットで記録を作成する
   ├─ records/ 配下の適切なパスに保存する
   └─ update-index.sh を実行する

2. テンプレート（templates/problem.md の内容）

3. 作業コンテキスト（collect-context.sh の出力）
   ├─ zsh コマンド履歴
   ├─ Chrome 検索履歴・訪問URL
   ├─ Copilot CLI セッションログ
   └─ Codex/Gemini ログ（あれば）
```

---

## 対応AIエージェント

### Codex CLI（推奨）

`auto-record.sh` が自動検出して使用します。

```bash
which codex
```

### Codexログ収集

`~/.codex/sessions/` や `~/.codex/log/` にログが存在する場合、`collect-context.sh` が自動的に収集します。

### Copilot CLI

`auto-record.sh --agent copilot` で使用します。

### Gemini CLI

`~/.gemini/logs/` または `~/.config/gemini/logs/` にログが存在する場合、自動収集します。

---

## カスタマイズ

### Codexで別のモデルを使う

`auto-record.sh` の Codex 呼び出し部分に `--model` を追加します。

```bash
printf '%s\n' "$PROMPT_CONTENT" | "$CODEX_BIN" exec \
  --model gpt-5 \
  --sandbox workspace-write \
  --ask-for-approval never \
  --cd "$ROOT_DIR" \
  --add-dir "$ROOT_DIR" \
  -
```

### Copilotで別のモデルを使う

```bash
copilot --model claude-opus-4.8 --allow-all -p "$PROMPT_CONTENT"
```

`auto-record.sh` の以下の行を編集してください：

```bash
# scripts/auto-record.sh 内
"$COPILOT_BIN" \
  --allow-all \
  --model claude-opus-4.8 \   # ← 追加
  --add-dir "$ROOT_DIR" \
  -p "$PROMPT_CONTENT"
```

### プロンプトをカスタマイズする

`auto-record.sh` の `cat > "$PROMPT_FILE"` ブロックを編集することで、  
AIへの指示内容を変更できます。

例：複数の問題を抽出させたい場合

```bash
# 「最も重要なものを1件」→「上位3件まで」に変更
2. 複数の問題がある場合は重要度順に最大3件出力する
```

### 収集ソースを追加する

`collect-context.sh` に新しいセクションを追加します：

```bash
# 例: fish shell の履歴を追加
echo "## 6. fish shell 履歴" >> "$OUTPUT_FILE"
if [[ -f ~/.local/share/fish/fish_history ]]; then
  tail -100 ~/.local/share/fish/fish_history >> "$OUTPUT_FILE"
fi
```

---

## セキュリティ上の注意

### 自動実行について

Codex 実行時は `--sandbox workspace-write --ask-for-approval never` を使います。
Copilot 実行時は `--allow-all` を使います。

どちらもAIがファイル作成やコマンド実行を自動で進めます。
内容が気になる場合は `--dry-run` でプロンプトを事前確認してください。

```bash
./scripts/auto-record.sh --dry-run
cat contexts/2026-06-17-2100-prompt.txt
```

確認後、問題なければ `--agent codex` または `--agent copilot` で実行します。

### コンテキストに含まれる情報

`collect-context.sh` が収集するデータには以下が含まれる可能性があります：

- シェルコマンドに含まれるパス・環境変数名
- ブラウザの検索クエリ・訪問URL（社内システムのURLなど）
- AIとの会話ログ（認証情報を入力していた場合）

これらは `contexts/` ディレクトリ（`.gitignore` 対象）にのみ保存され、  
GitHub には push されません。
