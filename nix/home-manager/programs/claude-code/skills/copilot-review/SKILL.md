---
name: copilot-review
version: 2.0.0
description: "GitHub Copilot PR review: Read Copilot's review comments on a PR, analyze each, fix code or reply with reasoning. Use when handling Copilot review feedback."
---

# Copilot PR Review Skill

GitHub CopilotによるPRレビューコメントを読み取り、各コメントを分析して、コード修正または理由付き返信を行う。

## ワークフロー

### Step 1: PR番号の特定

引数でPR番号が指定されていればそれを使う。なければ現在のブランチのPRを特定する:

```bash
gh pr view --json number -q '.number'
```

owner/repoも取得:

```bash
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

### Step 2: Copilotレビューコメントの取得

PRのレビューコメントを全件取得する（ページネーション対応）:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" --paginate
```

### Step 3: Copilotコメントのフィルタリング

取得したコメントから `user.login` が `copilot-pull-request-reviewer[bot]` のものだけを抽出する。

各コメントから以下の情報を取得:
- `id` — コメントID（返信時に使用）
- `body` — コメント本文
- `path` — 対象ファイルパス
- `line` (or `original_line`) — 対象行番号
- `diff_hunk` — 差分コンテキスト
- `in_reply_to_id` — 既にスレッドがある場合の親コメントID

**注意**: 既に返信済みのコメント（他のコメントの `in_reply_to_id` に自分のIDがあるもの）はスキップしてよい。

### Step 4: 各コメントの分析と対応

各Copilotコメントについて:

1. **対象ファイル・行を読む** — `path` と `line` から該当コードを読み取る
2. **コメント内容を分析** — 以下の判断基準で対応方針を決定

#### 判断基準

**コード修正する場合:**
- 実際のバグや潜在的な問題の指摘
- セキュリティ上の問題
- 明らかなパフォーマンス問題
- 型安全性の問題

**理由を返信して対応しない場合:**
- 既存の設計意図やアーキテクチャ方針に基づく実装
- フレームワークやライブラリの制約による実装
- 好みの問題（命名規則など、プロジェクト規約に沿っている場合）
- 過度な抽象化やDRY化の提案
- コンテキスト不足による誤った指摘

### Step 5: 対応の実行

#### コード修正する場合

1. 該当ファイルを修正
2. 修正内容を説明する返信を投稿:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" -f body="Fixed: <修正内容の簡潔な説明>"
```

#### 対応しない場合

理由を添えて返信:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" -f body="<対応しない理由の説明>"
```

### Step 6: サマリー表示

全コメントの対応結果をまとめて表示:

```
## Copilot Review 対応サマリー

| # | ファイル | 行 | 対応 | 内容 |
|---|---------|----|----|------|
| 1 | src/foo.ts | 42 | Fixed | null チェックを追加 |
| 2 | src/bar.ts | 15 | Replied | 設計意図による実装のため対応不要 |
```

コード修正があった場合は、確認せずそのままコミット＆プッシュする（gitmojiを使用）。

### Step 7: 再レビュー依頼

コード修正をコミット＆プッシュした後、Copilotに再レビューを依頼する。

まずCopilotの既存レビューを dismiss する:

```bash
# CopilotのレビューIDを取得
REVIEW_ID=$(gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews" --jq '.[] | select(.user.login == "copilot-pull-request-reviewer[bot]") | .id' | tail -1)

# レビューをdismiss
gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews/${REVIEW_ID}/dismissals" -f message="Changes applied, requesting re-review" -f event="DISMISS"
```

次にCopilotに再レビューをリクエスト:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers" -f "reviewers[]=copilot-pull-request-reviewer[bot]"
```

**注意**: 再レビュー依頼が失敗した場合（Copilotがreviewerとして設定できない場合など）はエラーを表示するが、スキル全体としては成功扱いとする。

### Step 8: 再レビュー結果の監視

再レビュー依頼後、一定間隔でCopilotのレビュー結果を監視する。

1. **初回チェック**: 3分後
2. **以降**: 2分間隔でチェック
3. **ユーザーは Ctrl+C でいつでも中断可能**であることを明示する

各チェックで以下を実行:

```bash
# Copilotの最新レビューステータスを確認
gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews" --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer[bot]")] | last | .state'
```

- **レビューが未完了**（`PENDING` またはレビューが増えていない）→ 次のチェックまで待機
- **レビュー完了** → 新しいコメントを確認

レビュー完了後:

```bash
# 新しいCopilotコメントを取得
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" --paginate --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer[bot]")]'
```

- **severity: high の指摘がある場合** → Step 2 に戻り、再度対応サイクルを実行
- **high の指摘がない場合** → 完了メッセージを表示して終了

```
✅ Copilot re-review 完了 — High指摘なし。対応サイクルを終了します。
```

**最大ループ回数**: 5回（無限ループ防止）。上限に達した場合はユーザーに報告して終了。
