# AI連携

## 概要

`auto-record.sh` は AI CLI の非対話モードを使って、  
コンテキスト収集から記録生成・保存まで全自動で行います。  
デフォルトは Copilot CLI で、`--agent` オプションで Codex CLI に切り替えられます。

```
collect-context.sh
      │ contexts/YYYY-MM-DD-HHMM.md
      ▼
プロンプト生成
      │ contexts/YYYY-MM-DD-HHMM-prompt.txt
      ▼
AI CLI（--agent で選択）
      │
      ├─ copilot --allow-all --add-dir .  （デフォルト）
      └─ codex exec -s workspace-write    （--agent=codex）
            │
            ├─ コンテキストを分析
            ├─ 問題を特定
            ├─ records/{project}/{task}/YYYY-MM-DD-{slug}.md を作成
            └─ update-index.sh を実行
```

---

## --agent オプション

| 値 | 挙動 |
|---|---|
| `auto`（デフォルト） | `copilot` を優先。見つからなければ `codex` にフォールバック |
| `copilot` | Copilot CLI のみ使用。未インストールならエラー終了 |
| `codex` | Codex CLI のみ使用。未インストールならエラー終了 |

```bash
./scripts/auto-record.sh               # auto（copilot 優先）
./scripts/auto-record.sh --agent=codex # Codex CLI を明示指定
```

---

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

### auto-record.sh での呼び出し方

**Copilot CLI（デフォルト）:**

```bash
copilot \
  --allow-all \
  --add-dir "$ROOT_DIR" \
  -p "$PROMPT_CONTENT"
```

**Codex CLI（`--agent=codex` 指定時）:**

```bash
cd "$ROOT_DIR"
codex exec \
  -s workspace-write \
  "$PROMPT_CONTENT"
```

| フラグ | CLI | 説明 |
|---|---|---|
| `--allow-all` | Copilot | ファイル作成・シェル実行をすべて自動許可 |
| `--add-dir` | Copilot | `records/` への書き込みを許可するためルートを指定 |
| `-p` | Copilot | プロンプト内容を渡す |
| `-s workspace-write` | Codex | ワークスペース書き込みを許可するサンドボックスモード |
| `exec` | Codex | 非対話（ワンショット）実行サブコマンド |

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

### Copilot CLI（標準・デフォルト）

`auto-record.sh` が自動検出して使用します。

```bash
which copilot  # → /opt/homebrew/bin/copilot など
```

### Codex CLI

`--agent=codex` オプションで使用できます。

```bash
./scripts/auto-record.sh --agent=codex
```

`codex exec -s workspace-write` で非対話実行します。  
`workspace-write` サンドボックスにより、リポジトリルートへの書き込みが許可されます。

### Gemini CLI

現時点では実行エージェントとして未対応です。  
`collect-context.sh` によるログ**収集**（`~/.gemini/logs/` など）のみ対応しています。

---

## カスタマイズ

### 別のモデルを使う

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

### `--allow-all` について

`--allow-all` フラグは Copilot CLI にすべての操作を自動許可します。  
`auto-record.sh` は `--add-dir` で対象ディレクトリを限定していますが、  
シェルコマンドの実行は制限されません。

**心配な場合は `--dry-run` でプロンプトを事前確認してください：**

```bash
./scripts/auto-record.sh --dry-run
cat contexts/2026-06-17-2100-prompt.txt  # 内容を確認
```

### コンテキストに含まれる情報

`collect-context.sh` が収集するデータには以下が含まれる可能性があります：

- シェルコマンドに含まれるパス・環境変数名
- ブラウザの検索クエリ・訪問URL（社内システムのURLなど）
- AIとの会話ログ（認証情報を入力していた場合）

これらは `contexts/` ディレクトリ（`.gitignore` 対象）にのみ保存され、  
GitHub には push されません。
