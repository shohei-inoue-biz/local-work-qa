# Getting Started

## 前提条件

| ツール | 用途 | 必須 |
|---|---|---|
| macOS (bash 3.x+) | スクリプト実行環境 | ✅ |
| [Copilot CLI](https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli) | AI記録生成 | ✅ |
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

### 3. Copilot CLI のインストール確認

```bash
copilot --version
# GitHub Copilot CLI 1.0.x
```

インストールされていない場合は [公式ドキュメント](https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli) を参照してください。

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
- [AI連携](./ai-integration.md) — Copilot CLIとの連携の仕組み
