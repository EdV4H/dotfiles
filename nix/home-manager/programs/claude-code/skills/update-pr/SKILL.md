---
name: update-pr
version: 1.0.0
description: "Update an existing PR: commit new changes with granular commits, push, and update PR title/description if needed."
---

# update-pr

既存PRに対して追加変更をコミット・プッシュし、必要に応じてPRタイトル・説明を更新する。

## 引数

- Optional: PR番号（省略時は現在のブランチに紐づくPRを自動検出）

## Behavior

### Step 1: 現在のPRを特定

```bash
BRANCH=$(git branch --show-current)
gh pr view "$BRANCH" --json number,title,body,url,headRefName,state
```

PRが見つからない場合は「このブランチにPRがありません」と報告して終了。
PRがクローズ/マージ済みの場合も報告して終了。

### Step 2: 変更を分析

```bash
git status
git diff
git diff --staged
```

変更がない場合は「コミットする変更がありません」と報告。
PRタイトル・説明の更新のみ行うか確認。

### Step 3: 論理的にコミットを分割

`/pull-request` と同じロジックで変更をグルーピング:

- **1コミット1目的**: 各コミットは1つの論理的変更のみ含む
- **独立性**: 各コミットは単独でビルド可能であること
- **分離の例**:
  - 機能追加とテストは別コミット
  - リファクタリングと機能変更は別コミット
  - ドキュメント更新は独立したコミット

### Step 4: コミット作成

各論理単位ごとにステージ・コミット:

```bash
git add <files>
git commit -m "<message>"
```

- コミットメッセージは「なぜ」にフォーカス
- 既存のコミットメッセージスタイルに合わせる（`git log` で確認）

### Step 5: Changeset対応

プロジェクトにchangesetが設定されている場合（`.changeset/` ディレクトリが存在）:

- 既存のchangesetがあるか確認
- 必要に応じて新しいchangesetを作成または既存のものを更新
- changesetファイルを別コミットとして含める

### Step 6: プッシュ

```bash
git push
```

force pushが必要な場合（rebase後など）はユーザーに確認してから `--force-with-lease` を使用。

### Step 7: PRタイトル・説明の更新

現在の変更内容を踏まえて、PRタイトルと説明の更新が必要か判断する。

```bash
# 現在のPR情報を取得
gh pr view <NUMBER> --json title,body,commits
```

更新が必要な場合:

```bash
gh pr edit <NUMBER> --title "<新タイトル>" --body "$(cat <<'EOF'
## Summary
<更新された説明>

## Test plan
<テスト計画>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**更新の判断基準**:
- 新しいコミットでPRのスコープが変わった場合 → タイトル・説明を更新
- バグ修正やレビュー指摘対応の場合 → 説明に対応内容を追記
- 軽微な修正（typo、lint等）→ 更新不要

### Step 8: Copilotレビュー再依頼 & 対応

前回のCopilotレビューコメントが解決済みか確認し、必要に応じて再レビューを依頼:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers" \
  -f "reviewers[]=copilot-pull-request-reviewer[bot]"
```

`/copilot-review` スキルを実行してCopilotのレビューコメントに対応する。

### Step 9: CI監視

```bash
gh pr checks <NUMBER> --watch --fail-fast
```

- **全チェック通過**: auto-mergeを有効化（Copilotレビュー対応完了後）
- **チェック失敗**: 失敗したチェック名を報告

### Step 10: サマリー表示

```
## PR Update 完了

- PR: <TITLE> (#<NUMBER>)
- URL: <URL>
- 新規コミット: N件
- タイトル更新: あり/なし
- 説明更新: あり/なし
- CI: 通過/失敗/待機中
```

## 注意事項

- 既存のコミットを amend しない（新しいコミットとして追加する）
- force push はユーザーの明示的な同意がある場合のみ
- PRの説明を更新する際、既存の内容を完全に上書きするのではなく、必要な部分のみ更新する
- auto-merge は Copilot レビュー対応完了後に有効化する
