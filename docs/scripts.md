# スクリプトリファレンス

## 一覧

| スクリプト | 役割 | 主な用途 |
|---|---|---|
| [`auto-record.sh`](#auto-recordsh) | コンテキスト収集→AI記録生成のメインエントリポイント | 作業終了時に実行 |
| [`collect-context.sh`](#collect-contextsh) | 複数ソースからコンテキストを収集 | auto-record.sh から呼ばれる |
| [`new-record.sh`](#new-recordsh) | 対話形式で記録を手動作成 | 手動記録 |
| [`search.sh`](#searchsh) | キーワード・タグ・ステータスで全記録を検索 | 過去の知識を参照 |
| [`stats.sh`](#statssh) | 統計サマリーの表示 | 振り返り・傾向把握 |
| [`status-update.sh`](#status-updatesh) | 記録のステータスを対話的に更新 | 解決後の更新 |
| [`update-index.sh`](#update-indexsh) | インデックスの再生成 | 記録追加・変更後に実行 |

---

## auto-record.sh

コンテキスト収集から記録生成まで一括で行うメインスクリプト。

### 使い方

```bash
./scripts/auto-record.sh                          # フル自動
./scripts/auto-record.sh --agent codex            # Codex CLI を使う
./scripts/auto-record.sh --agent copilot          # Copilot CLI を使う
./scripts/auto-record.sh contexts/YYYY-MM-DD.md  # 既存コンテキストを使用
./scripts/auto-record.sh --dry-run               # プロンプト生成のみ（AI呼び出しなし）
./scripts/auto-record.sh --help
```

### オプション

| オプション | 説明 |
|---|---|
| `--agent auto` | 利用可能なAI CLIを自動選択。Codex があれば Codex、なければ Copilot を使う |
| `--agent codex` / `--codex` | Codex CLI で記録を生成する |
| `--agent copilot` / `--copilot` | Copilot CLI で記録を生成する |
| `--dry-run` | コンテキスト収集とプロンプト生成のみ。AI CLI は起動しない |
| `--help` / `-h` | ヘルプを表示 |
| `[コンテキストファイル]` | 既存の contexts/*.md を指定すると収集をスキップ |

### 処理の流れ

1. `collect-context.sh` を実行してコンテキストを収集
2. テンプレート + コンテキストからプロンプトファイル（`*-prompt.txt`）を生成
3. Codex CLI または Copilot CLI を非対話で起動
4. AI CLI が記録ファイルを `records/` に保存し、`update-index.sh` を実行

### Codex 実行時のコマンド

```bash
codex exec --sandbox workspace-write --ask-for-approval never --cd "$ROOT_DIR" --add-dir "$ROOT_DIR" -
```

プロンプト本文は標準入力で渡します。`workspace-write` なので、このツールのディレクトリ配下を書き込みできます。

### Copilot 実行時のコマンド

```bash
copilot --allow-all --add-dir "$ROOT_DIR" -p "$PROMPT_CONTENT"
```

### 出力ファイル

| ファイル | 説明 |
|---|---|
| `contexts/YYYY-MM-DD-HHMM.md` | 収集したコンテキスト |
| `contexts/YYYY-MM-DD-HHMM-prompt.txt` | AI CLI に渡すプロンプト |
| `records/{project}/{task}/YYYY-MM-DD-{slug}.md` | 生成された問題記録 |

---

## collect-context.sh

今日の作業コンテキストを複数ソースから収集してMarkdownファイルに書き出す。

### 使い方

```bash
./scripts/collect-context.sh
```

引数なし。常に今日分を収集する。

### 収集ソース

| ソース | 収集内容 | 条件 |
|---|---|---|
| `~/.zsh_history` | 直近200件のコマンド（近似） | 常時（タイムスタンプなし環境では末尾200件） |
| Chrome History DB | 今日の検索クエリ・訪問URL | `~/Library/.../Chrome/Default/History` が存在する場合 |
| Copilot CLI セッションDB | 今日の会話ターン | `~/.copilot/session-store.db` が存在する場合 |
| Codex CLI ログ | 今日のログファイル・セッションJSONL | `~/.codex/sessions/` などが存在する場合 |
| Gemini CLI ログ | 今日のログファイル | `~/.gemini/logs/` などが存在する場合 |

### 注意事項

- **Chrome が起動中の場合**、ロック競合を避けるためにDBをコピーしてから参照します
- zsh の `EXTENDED_HISTORY` が有効な場合はタイムスタンプでフィルタします
- Codex/Gemini が未インストールの場合は警告を出してスキップします

### カスタマイズ

スクリプト内の以下の変数を編集することで動作を変更できます：

```bash
CHROME_HISTORY="$HOME/Library/Application Support/Google/Chrome/Default/History"
COPILOT_DB="$HOME/.copilot/session-store.db"
```

Firefox や他のブラウザを使う場合は `CHROME_HISTORY` を書き換えてください  
（ただし Firefox の History DB スキーマは異なるため SQL も修正が必要です）。

---

## new-record.sh

対話形式で問題記録ファイルを作成する。AI を使わずに記録したい場合に使用。

### 使い方

```bash
./scripts/new-record.sh
```

### 対話の流れ

```
リポジトリ/プロジェクト名: my-repo
タスク名（例: setup-ci, add-auth）: setup-ci
問題タイトル（一文）: Docker buildx が GitHub Actions 上で失敗する
タグ（カンマ区切り、例: build,ci,docker）: ci,docker,github-actions
使用したAIエージェント（例: Codex CLI）: Codex CLI
```

### 出力

- `records/{project}/{task-slug}/YYYY-MM-DD-{title-slug}.md` にテンプレートを元にしたファイルを作成
- `records/{project}/_index.md` を作成（存在しない場合）
- `records/_index.md` に行を追記

### 注意

- 同名ファイルが既に存在する場合は作成を中断します
- 記録内容（問題詳細・試み・解決策など）は生成後にエディタで記入してください

---

## search.sh

`records/` 配下の全記録をキーワード・タグ・ステータス・プロジェクトで横断検索する。

### 使い方

```bash
./scripts/search.sh <キーワード>
./scripts/search.sh [オプション] [キーワード]
```

### オプション

| オプション | 短縮形 | 説明 | 例 |
|---|---|---|---|
| `--tag <tag>` | `-t` | タグで絞り込む | `--tag docker` |
| `--project <name>` | `-p` | プロジェクト名で絞り込む | `-p my-repo` |
| `--status <status>` | `-s` | ステータスで絞り込む | `--status unresolved` |
| `--help` | `-h` | ヘルプを表示 | |

ステータスの値: `resolved` / `unresolved` / `workaround`

### 出力例

```
---
📄 Docker buildx が GitHub Actions 上で失敗する
   プロジェクト: sample-repo  |  日付: 2026-06-17  |  ステータス: resolved
   タグ: [ci, github-actions, docker]
   パス: records/sample-repo/setup-ci/2026-06-17-docker-buildx-github-actions.md
   --- マッチ箇所 ---
   10:# Docker buildx が GitHub Actions 上で失敗する

✅ 1 件の記録が見つかりました。
```

### 使用例

```bash
# キーワードで検索
./scripts/search.sh "認証"
./scripts/search.sh CORS

# タグ + ステータスの組み合わせ
./scripts/search.sh --tag ci --status unresolved

# プロジェクト内のキーワード検索
./scripts/search.sh -p my-repo "timeout"
```

---

## stats.sh

記録全体の統計サマリーを表示する。

### 使い方

```bash
./scripts/stats.sh
```

引数なし。

### 出力内容

1. **総記録数**
2. **ステータス別** — resolved / unresolved / workaround の件数（バーグラフ付き）
3. **プロジェクト別** — リポジトリごとの記録件数
4. **タグ別（上位10）** — よく使われているタグのランキング
5. **最近の記録（5件）** — 最新順で一覧

### 出力例

```
=====================================
  📊 local-work-qa 統計サマリー
=====================================

総記録数: 12 件

【ステータス別】
  ✅ resolved     10 件  ██████████
  ❌ unresolved    2 件  ██

【プロジェクト別】
  my-repo                        7 件  ███████
  sample-repo                    5 件  █████

【タグ別（上位 10）】
  docker                    5 件  █████
  ci                        4 件  ████
  ...
```

---

## status-update.sh

既存の記録ファイルのステータスフィールドを対話形式で更新する。

### 使い方

```bash
./scripts/status-update.sh
```

### 対話の流れ

```
記録一覧:
   1) [resolved    ] sample-repo / Docker buildx が GitHub Actions 上で失敗する
   2) [unresolved  ] my-repo / JWT リフレッシュトークンが期限切れにならない

更新する記録の番号を入力してください: 2

対象: JWT リフレッシュトークンが期限切れにならない
現在のステータス: unresolved

新しいステータスを選択してください:
  1) resolved   - 解決済み
  2) unresolved - 未解決
  3) workaround - ワークアラウンドあり

番号を入力してください [1-3]: 1

✅ ステータスを更新しました: unresolved → resolved
```

### 注意

- ステータス更新後は `./scripts/update-index.sh` の実行を推奨します（スクリプトが案内します）

---

## update-index.sh

`records/` を全走査してインデックスファイルを再生成する。

### 使い方

```bash
./scripts/update-index.sh
```

### 更新されるファイル

| ファイル | 内容 |
|---|---|
| `records/_index.md` | 全記録のグローバルインデックス（プロジェクト別セクション付き） |
| `records/{project}/_index.md` | プロジェクトごとのインデックス |

### 実行タイミング

以下の操作の後に実行してください：

- `new-record.sh` で記録を追加した後
- 記録ファイルを手動で編集・削除した後
- `status-update.sh` でステータスを変更した後
- `auto-record.sh` は内部で自動実行するため通常は不要

### インデックスの構造

```markdown
# 記録インデックス

| 日付 | プロジェクト | タスク | 問題タイトル | ステータス | タグ |
|---|---|---|---|---|---|
| 2026-06-17 | sample-repo | ... | [タイトル](パス) | resolved | [ci] |

---

## プロジェクト別

### sample-repo

| 日付 | タスク | 問題タイトル | ステータス | タグ |
|---|---|---|---|---|
```
