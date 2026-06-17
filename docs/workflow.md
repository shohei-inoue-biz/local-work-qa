# ワークフロー

## 基本サイクル

```
作業開始
   │
   ▼
【作業・デバッグ・調査】
   │  詰まる・問題が発生する
   ▼
./scripts/auto-record.sh   ← 作業終了時に実行
   │
   ├─ コンテキスト収集（zsh履歴・Chrome・AIログ）
   ├─ プロンプト生成
   └─ Copilot CLI が自動で記録ファイルを生成・保存
```

---

## シナリオ別の使い方

### シナリオ1: 作業終了時に丸ごと自動化（推奨）

```bash
cd ~/local-work-qa
./scripts/auto-record.sh
```

Copilot CLI が起動し、今日の作業を分析して `records/` に記録を保存します。  
確認後に必要なら内容を手で補記してください。

---

### シナリオ2: コンテキストを先に確認してから生成したい

```bash
# ステップ1: コンテキストだけ収集
./scripts/collect-context.sh
# → contexts/2026-06-17-2100.md が生成される

# ステップ2: 内容を確認・手動補記
$EDITOR contexts/2026-06-17-2100.md

# ステップ3: 確認済みコンテキストを使って記録生成
./scripts/auto-record.sh contexts/2026-06-17-2100.md
```

---

### シナリオ3: 内容を確認してから AI に渡したい（dry-run）

```bash
./scripts/auto-record.sh --dry-run

# 生成されたプロンプトを確認
cat contexts/2026-06-17-2100-prompt.txt

# 問題なければ Copilot CLI のチャットで実行
# 「contexts/2026-06-17-2100-prompt.txt を読んで記録を生成して」
```

---

### シナリオ4: 手動で記録を作成する

AI に頼らず自分で書きたい場合：

```bash
./scripts/new-record.sh
```

対話形式でリポジトリ名・タスク名・タイトル・タグ・エージェント名を入力します。  
生成されたファイルをエディタで開いて内容を記入してください。

---

### シナリオ5: 過去の記録を活用する

#### 同じ問題で詰まった気がするとき

```bash
# キーワード検索
./scripts/search.sh "認証エラー"
./scripts/search.sh docker
./scripts/search.sh "CORS"

# タグで絞り込み
./scripts/search.sh --tag ci
./scripts/search.sh --tag docker --tag authentication

# 未解決のものだけ確認
./scripts/search.sh --status unresolved
```

#### 特定プロジェクトの記録を確認

```bash
./scripts/search.sh -p my-repo
./scripts/search.sh -p my-repo --tag auth
```

---

### シナリオ6: 解決したらステータスを更新

```bash
./scripts/status-update.sh
# → 番号を選んで resolved に変更
./scripts/update-index.sh
```

---

### シナリオ7: 定期的に振り返る

```bash
./scripts/stats.sh
```

どのプロジェクト・タグで詰まることが多いかを可視化します。  
改善の優先度や学習の方向性を決める参考になります。

---

## 推奨ルーティン

| タイミング | コマンド | 目的 |
|---|---|---|
| 作業終了時（毎日） | `./scripts/auto-record.sh` | 今日の詰まりを記録 |
| 問題が解決したとき | `./scripts/status-update.sh` | ステータスを resolved に更新 |
| 同じ問題で詰まりそうなとき | `./scripts/search.sh キーワード` | 過去の解決策を参照 |
| 週1回 | `./scripts/stats.sh` | 傾向を把握 |

---

## tips

- `auto-record.sh` は **別インスタンスの Copilot CLI** を `--allow-all` で起動します。  
  ファイルの読み書きやコマンド実行が自動で行われるため、内容が気になる場合は `--dry-run` で先に確認してください。
- `records/` 直下の `_index.md` は `update-index.sh` で自動生成されます。手動編集は不要です。
- コンテキストファイル（`contexts/`）は `.gitignore` 対象のため push されません。定期的に削除して構いません。
