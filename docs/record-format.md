# 記録フォーマット

## ファイルの命名規則

```
records/{project}/{task-slug}/YYYY-MM-DD-{problem-slug}.md
```

| 部分 | 説明 | 例 |
|---|---|---|
| `project` | リポジトリ・プロジェクト名（ハイフン区切り） | `my-app`, `infra-tools` |
| `task-slug` | 何をしようとしていたか（英小文字・ハイフン） | `setup-ci`, `add-auth` |
| `YYYY-MM-DD` | 記録作成日 | `2026-06-17` |
| `problem-slug` | 問題の一言要約（英小文字・ハイフン・最大50文字） | `docker-buildx-fails-on-actions` |

### 例

```
records/
└── my-app/
    ├── _index.md
    ├── setup-ci/
    │   └── 2026-06-17-docker-buildx-fails-on-actions.md
    └── add-auth/
        └── 2026-06-18-jwt-refresh-token-not-expiring.md
```

---

## Frontmatter

各記録ファイルの先頭に YAML frontmatter を記述します。  
`update-index.sh` と `search.sh` はこの frontmatter を読み取ります。

```yaml
---
date: 2026-06-17
project: my-app
task: GitHub Actions で CI を設定する
status: resolved
tags: [ci, github-actions, docker]
agent_used: [Codex CLI]
---
```

### フィールド詳細

| フィールド | 型 | 説明 | 必須 |
|---|---|---|---|
| `date` | `YYYY-MM-DD` | 記録作成日 | ✅ |
| `project` | 文字列 | リポジトリ・プロジェクト名 | ✅ |
| `task` | 文字列 | 何をしようとしていたか（日本語可） | ✅ |
| `status` | enum | `resolved` / `unresolved` / `workaround` | ✅ |
| `tags` | 配列 | 分類タグ（英小文字推奨） | ✅ |
| `agent_used` | 配列 | 利用したAIエージェント・ツール | 任意 |

### status の使い分け

| 値 | 意味 |
|---|---|
| `resolved` | 問題が完全に解決した |
| `unresolved` | まだ解決していない・原因不明 |
| `workaround` | 根本解決ではないが回避策がある |

### tags の推奨値

よく使われるタグの例（自由に追加可能）：

```
言語・ランタイム: go, python, node, ruby, rust, java
フレームワーク:   react, nextjs, rails, django, gin
インフラ:         docker, k8s, terraform, aws, gcp, azure
CI/CD:            ci, github-actions, circleci, jenkins
開発ツール:       git, vscode, homebrew
問題種別:         build, test, deploy, auth, performance, security
```

---

## 本文構造

```markdown
# [問題タイトル：一文で表す]

## 状況・背景

何をしようとしていたか、どんな状態で問題が発生したかを記述する。

## 環境

- OS:
- 言語/フレームワーク:
- バージョン:
- その他関連ツール:

## 問題の内容

どこで詰まったか。エラーメッセージや再現手順を記述する。

```
# エラーメッセージや関連コードをここに
```

## 試みた対策

### 試み 1: [対策名]

- **内容**: 何をしたか
- **結果**: ❌ うまくいかなかった
- **理由**: なぜ効果がなかったか

### 試み N: [対策名]

- **内容**: 何をしたか
- **結果**: ✅ 解決した / ⚠️ 部分的に解決した

## 根本原因

問題の本質的な原因。

## 解決策

最終的にどう解決したか。再現可能な手順で記述する。

```bash
# 解決に使ったコマンドやコードをここに
```

## 学び・次回への教訓

- 同じ問題を防ぐには何を気をつければよいか
- この問題から得た知識・気づき
- 参考になったリンク・ドキュメント

## 関連記録

- [関連する別の問題記録へのリンク]
```

---

## 書き方のコツ

### 問題タイトル

❌ 悪い例: `エラーが出た`  
✅ 良い例: `docker buildx build が "no such file or directory" で失敗する`

一文で「何が」「どうなったか」が分かるように書く。

### 試みた対策

うまくいかなかった試みも必ず残す。  
「試み1で❌だった」という情報が、同じ間違いを繰り返さない最大の資産になる。

### 根本原因

解決策だけでなく「なぜそうなったか」を書く。  
原因が分かれば、類似問題に応用できる。

### 学び

「次回の自分へのメモ」として書く。  
3ヶ月後の自分が読んでも理解できるレベルを目指す。

---

## 完成例

```markdown
---
date: 2026-06-17
project: my-app
task: GitHub Actions で CI を設定する
status: resolved
tags: [ci, github-actions, docker]
agent_used: [Codex CLI]
---

# Docker buildx が GitHub Actions 上で失敗する

## 状況・背景

`my-app` のCIパイプラインを構築中。`docker buildx build` を使ったマルチプラットフォームビルドを
Actions に追加しようとした。

## 環境

- OS: Ubuntu 22.04 (GitHub Actions runner)
- ツール: Docker 24.x, `docker/build-push-action@v5`

## 問題の内容

```
ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```

ローカルでは `docker buildx build .` が通るのに Actions 上でのみ失敗する。

## 試みた対策

### 試み 1: `context: .` を明示的に指定

- **内容**: `docker/build-push-action` の `context: .` を明示的に記述
- **結果**: ❌ うまくいかなかった
- **理由**: 問題は context ではなく Dockerfile の場所の指定方法にあった

### 試み 2: `working-directory` をステップに追加

- **内容**: ステップに `working-directory: ./app` を追加
- **結果**: ❌ うまくいかなかった
- **理由**: `docker/build-push-action` は `working-directory` を無視する

### 試み 3: `file` パラメータで Dockerfile パスを明示

- **内容**: `file: ./app/Dockerfile` と `context: ./app` を両方指定
- **結果**: ✅ 解決した

## 根本原因

`docker/build-push-action` は `working-directory` を継承しない。
`context` と `file` を明示的に指定する必要がある。

## 解決策

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: ./app
    file: ./app/Dockerfile
    push: true
    tags: ghcr.io/org/image:latest
```

## 学び・次回への教訓

- `docker/build-push-action` は `working-directory` を無視する。`context` と `file` は常に明示する
- Codex CLI に調査を依頼したところ、公式ドキュメントの該当箇所をすぐに特定してくれた

## 関連記録

- なし
```
