# local-work-qa / frontend

`records/` に蓄積した問題記録をブラウザで閲覧・検索できる Web UI。  
Next.js + React 製。ローカル専用。

---

## スタック

| 技術 | バージョン | 用途 |
|---|---|---|
| Next.js | 15 | App Router / SSG |
| React | 19 | UI |
| TypeScript | 5 | 型安全 |
| Sass | 1 | スタイル（`globals.scss` 一本管理）|
| gray-matter | 4 | frontmatter パース |
| react-markdown | 9 | Markdown レンダリング |
| remark-gfm | 4 | GitHub Flavored Markdown |

---

## 起動

```bash
cd frontend
pnpm install   # 初回のみ
pnpm dev       # → http://localhost:3000
```

> **前提**: pnpm がなければ `npm install -g pnpm` でインストール

---

## ディレクトリ構造

```
frontend/
├── app/
│   ├── layout.tsx               # 共通レイアウト（ナビバー）
│   ├── page.tsx                 # 一覧ページ（サーバーコンポーネント）
│   ├── globals.scss             # 全スタイル（デザイントークン〜コンポーネント）
│   └── records/
│       └── [...slug]/
│           └── page.tsx         # 記録詳細ページ
├── components/
│   ├── RecordList.tsx           # 検索・フィルタ UI（クライアントコンポーネント）
│   └── MarkdownContent.tsx      # Markdown レンダラー（クライアントコンポーネント）
├── lib/
│   └── records.ts               # ../records/ の読み込み・パースユーティリティ
├── types/
│   └── index.ts                 # 共通型定義
├── next.config.js
├── tsconfig.json
└── package.json
```

---

## 機能

### 一覧ページ（`/`）

| 機能 | 説明 |
|---|---|
| キーワード検索 | タイトル・本文・タグ・プロジェクト名をリアルタイム検索 |
| プロジェクトフィルタ | サイドバーでリポジトリ単位に絞り込み |
| ステータスフィルタ | `resolved` / `unresolved` / `workaround` で絞り込み |
| タグフィルタ | タグをクリックして絞り込み（複数選択可） |

### 詳細ページ（`/records/[...slug]`）

- Markdown をフルレンダリング（テーブル・コードブロック・GFM 対応）
- frontmatter のメタデータ（日付・ステータス・タグ・使用 AI）を表示
- 一覧へ戻るナビゲーション

---

## データソース

`../records/` 配下の `.md` ファイルをサーバーサイドで直接読み込みます（`_index.md` は除外）。  
新しい記録を追加した後は、開発サーバーを再起動またはページをリロードすれば即反映されます。

### 対応 frontmatter

```yaml
---
date: 2026-06-17          # 必須
project: my-app           # 必須
task: タスク名             # 必須
status: resolved          # 必須: resolved | unresolved | workaround
tags: [ci, docker]        # 必須
agent_used: [Copilot CLI] # 任意
---
```

---

## スタイル

すべてのスタイルは `app/globals.scss` に集約されています。  
CSS カスタムプロパティでデザイントークンを管理しているため、カラーや余白の変更は `:root` ブロックを編集するだけです。

```scss
:root {
  --primary: #0969da;   /* アクセントカラー */
  --bg: #f6f8fa;        /* ページ背景 */
  --surface: #ffffff;   /* カード背景 */
  /* ... */
}
```

---

## ビルド（本番）

```bash
pnpm build
pnpm start
```

> `records/` はビルド時に静的に読み込まれます。記録を追加した場合は再ビルドが必要です。  
> 開発時は `pnpm dev` を推奨（ファイル変更を動的に反映）。
