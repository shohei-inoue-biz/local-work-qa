# Getting Started

## 前提条件

| ツール | 用途 | 必須 |
|---|---|---|
| macOS (bash 3.x+) | スクリプト実行環境 | ✅ |
| Codex CLI | AI記録生成 | 推奨 |
| Copilot CLI | AI記録生成 | 任意 |
| zsh | コマンド履歴収集 | ✅ |
| Google Chrome | ブラウザ履歴収集 | 任意 |
| python3 | Chrome履歴の日付変換 | 任意 |
| sqlite3 | DBクエリ | 任意 |

---

## インストール

### 1. リポジトリをクローン

```bash
git clone https://github.com/{your-username}/local-work-qa.git ~/local-work-qa
cd ~/local-work-qa
```

### 2. スクリプトに実行権限を付与

```bash
chmod +x scripts/*.sh
```

### 3. Codex CLI のインストール確認

```bash
codex --version
```

`codex` コマンドが見つかれば準備完了です。

Copilot CLI を使いたい場合は、こちらも確認します。

```bash
copilot --version
```

---

## まず1回使ってみる

作業が終わったあとに、次を実行します。

```bash
cd ~/local-work-qa
./scripts/auto-record.sh --agent codex
```

処理の流れは以下です。

1. `contexts/` に今日の作業コンテキストを保存
2. `contexts/*-prompt.txt` にAIへ渡す指示文を保存
3. Codex が `records/` に問題記録を作成
4. `records/_index.md` を更新

先に内容を確認したい場合は、AIを起動しない `--dry-run` を使います。

```bash
./scripts/auto-record.sh --dry-run
cat contexts/YYYY-MM-DD-HHMM-prompt.txt
```

---

## ディレクトリ構造

```
local-work-qa/
├── README.md
├── .gitignore               # records/ contexts/ は追跡対象外
├── docs/                    # このドキュメント群
├── templates/
│   └── problem.md           # 問題記録のテンプレート
├── contexts/                # 【gitignore対象】収集したコンテキスト・プロンプト
│   └── YYYY-MM-DD-HHMM.md
├── records/                 # 【gitignore対象】問題記録の蓄積
│   ├── _index.md
│   └── {repo-name}/
│       ├── _index.md
│       └── {task-slug}/
│           └── YYYY-MM-DD-{problem-slug}.md
└── scripts/
    ├── auto-record.sh       # メインエントリポイント（コンテキスト収集→AI生成）
    ├── collect-context.sh   # コンテキスト収集のみ
    ├── new-record.sh        # 手動で記録を作成
    ├── search.sh            # 記録を検索
    ├── stats.sh             # 統計サマリー
    ├── status-update.sh     # ステータス更新
    └── update-index.sh      # インデックス再生成
```

---

## セキュリティ設計

`records/` と `contexts/` は `.gitignore` によって Git 追跡対象から除外されています。

| ディレクトリ | 除外理由 |
|---|---|
| `records/` | 業務内容・社内情報・未解決の問題が含まれる可能性 |
| `contexts/` | シェル履歴・ブラウザ履歴・AIログ（認証情報やURLが混入しうる） |

チームで共有したい場合は、**プライベートリポジトリ**での管理を推奨します。

---

## 次のステップ

- [ワークフロー](./workflow.md) — 日々の使い方
- [スクリプトリファレンス](./scripts.md) — 各スクリプトの詳細
- [記録フォーマット](./record-format.md) — Markdownの書き方
- [AI連携](./ai-integration.md) — Codex/Copilot CLIとの連携の仕組み
