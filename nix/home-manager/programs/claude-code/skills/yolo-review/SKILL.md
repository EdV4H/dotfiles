---
name: yolo-review
version: 1.0.0
description: "Review a PR with 'yolo' label: read the diff, judge safety, and approve if acceptable."
---

# yolo-review

`yolo` ラベルが付いたPRの差分を読み、安全性を判定して問題なければ approve する。

## Arguments

- Required: `<number>` — PR番号
- Required: `<repo>` — リポジトリ（owner/repo 形式）

## Behavior

### Step 1: PRの情報を取得

```bash
gh pr view <number> -R <repo> --json title,body,labels,files,additions,deletions,author
```

`yolo` ラベルが付いていない場合は「yolo ラベルがありません」と報告して終了。

### Step 2: 差分を取得

```bash
gh pr diff <number> -R <repo>
```

### Step 3: 変更内容を判定

以下の観点でレビューする:

**即 approve できるケース（低リスク）:**
- 依存関係の更新（package.json, Cargo.toml, go.mod 等のバージョンバンプ）
- ドキュメントのみの変更
- テストの追加・修正のみ
- CI/CD 設定の軽微な変更
- コードフォーマット・lintの修正
- タイポ修正
- 自動生成ファイルの更新（lockfile, changeset等）

**approve してはいけないケース（要人間レビュー）:**
- セキュリティに関わる変更（認証、認可、暗号化、秘密情報の扱い）
- データベースマイグレーション
- API の破壊的変更
- ビジネスロジックの大幅な変更
- 環境変数やシークレットの追加・変更
- 100行を超える実コード変更

### Step 4: 判定結果に応じてアクション

**approve する場合:**

```bash
gh pr review <number> -R <repo> --approve --body "$(cat <<'EOF'
LGTM 👍

## Auto-review summary
- <変更内容の1行要約>
- Risk: Low
- Reason: <approve理由>

🤖 Reviewed by Claude Code (yolo-review)
EOF
)"
```

**approve しない場合:**

1. コメントで理由を説明:

```bash
gh pr review <number> -R <repo> --comment --body "$(cat <<'EOF'
## Auto-review: 手動レビューが必要です

yolo ラベルが付いていますが、以下の理由で自動 approve できません:

- <理由1>
- <理由2>

人間のレビュワーによる確認をお願いします。

🤖 Reviewed by Claude Code (yolo-review)
EOF
)"
```

2. `yolo` ラベルを削除して再度の自動レビューを防止:

```bash
gh pr edit <number> -R <repo> --remove-label "yolo"
```

### Step 5: 結果を出力

```
## yolo-review complete

- PR: <title> (#<number>)
- Repo: <repo>
- Decision: Approved / Needs human review
- Reason: <理由>
```

## Notes

- approve は低リスクな変更のみ。判断に迷ったら approve しない
- セキュリティに関わる変更は絶対に自動 approve しない
- gh-review-watcher の on_poll Hook から自動呼び出しされる
