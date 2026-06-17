# local-work-qa

AIエージェントを活用した作業・問題解決ログの記録・蓄積システム。

プロジェクト・タスク・リポジトリ横断で「問題 → 試行錯誤 → 解決」の知識を蓄積し、同じ詰まりを繰り返さないようにする。

---

## ディレクトリ構造

```
local-work-qa/
├── README.md               # このファイル
├── templates/
│   └── problem.md          # 問題記録のテンプレート
├── contexts/               # 収集したコンテキスト・プロンプトの一時保存
│   └── YYYY-MM-DD-HHMM.md
├── records/
│   ├── _index.md           # 全記録のインデックス
│   ├── {repo-name}/
│   │   ├── _index.md       # リポジトリ内インデックス
│   │   └── {task-slug}/
│   │       └── {YYYY-MM-DD}-{problem-slug}.md
│   └── ...
└── scripts/
    ├── new-record.sh        # 新規記録作成スクリプト（手動）
    ├── collect-context.sh   # 作業コンテキストを自動収集（履歴・Chrome・AIログ）
    ├── auto-record.sh       # コンテキスト収集 → Copilot CLI用プロンプト生成
    ├── update-index.sh      # インデックス再生成（グローバル＋リポジトリ別）
    ├── search.sh            # キーワード・タグ・ステータスで検索
    ├── status-update.sh     # 記録のステータスを対話形式で更新
    └── stats.sh             # 統計サマリー表示（プロジェクト別・ステータス別・タグ別）
```

---

## 記録の作り方

### 方法1: コンテキスト自動収集 → AI生成（推奨）

作業終了時に実行するだけ。zsh履歴・Chrome検索履歴・AIログを自動収集してプロンプトを生成する。

```bash
# コンテキスト収集 + Copilot CLI向けプロンプト生成
./scripts/auto-record.sh
```

生成された `contexts/YYYY-MM-DD-HHMM-prompt.txt` を Copilot CLI に渡す：

```
contexts/2026-06-17-2100-prompt.txt を読んで問題記録を生成して
records/{リポジトリ名}/{タスク名}/ に保存して
```

### 方法2: 手動で作成する場合

```bash
# 対話形式で新規記録を作成
./scripts/new-record.sh
```

### 方法3: Copilot CLI に直接依頼する場合

```
今日のセッションで直面した問題をtemplates/problem.mdの形式でまとめて
records/{リポジトリ名}/{タスク名}/ に保存して
```

---

## 検索・活用方法

```bash
# コンテキストだけ収集してファイルに保存（自分でプロンプトを調整したい場合）
./scripts/collect-context.sh

# キーワードで全記録を検索
./scripts/search.sh docker

# タグで絞り込む
./scripts/search.sh --tag ci

# ステータスで絞り込む
./scripts/search.sh --status unresolved

# プロジェクト＋キーワードの組み合わせ
./scripts/search.sh -p my-repo authentication

# 記録のステータスを更新する
./scripts/status-update.sh

# インデックスを手動で再生成する
./scripts/update-index.sh

# 統計サマリーを表示する
./scripts/stats.sh
```

---

## ドキュメント

詳細は `docs/` を参照してください。

| ドキュメント | 内容 |
|---|---|
| [getting-started.md](./docs/getting-started.md) | インストール・ディレクトリ構造・セキュリティ設計 |
| [workflow.md](./docs/workflow.md) | シナリオ別の使い方・推奨ルーティン |
| [scripts.md](./docs/scripts.md) | 各スクリプトのオプション・挙動・出力の詳細 |
| [record-format.md](./docs/record-format.md) | 記録ファイルのフォーマット・frontmatter・書き方のコツ |
| [ai-integration.md](./docs/ai-integration.md) | Copilot CLI連携の仕組み・カスタマイズ方法 |

---

## 記録の構成要素

| フィールド | 説明 |
|---|---|
| `project` | リポジトリ・プロジェクト名 |
| `task` | 何をしようとしていたか |
| `environment` | OS・言語・フレームワーク・バージョン等 |
| `problem` | どこで何に詰まったか（エラーメッセージ含む）|
| `attempts` | 試みた対策と結果（うまくいかなかったものも含む）|
| `root_cause` | 原因の特定 |
| `solution` | 最終的な解決策 |
| `lessons` | 学び・次回への教訓 |
| `agent_used` | 使ったAIエージェント・ツール |
| `tags` | 分類タグ |
# local-work-qa
