---
name: fix-issue
version: 1.0.0
description: "Resolve a GitHub Issue: read the issue, plan a fix, implement it, and close the issue when done."
---

# Fix Issue Skill

GitHub Issueの内容を読み取り、対応方針を立て、実装し、完了したらIssueをCloseする。

## 引数

- Issue URL（例: `https://github.com/owner/repo/issues/123`）またはIssue番号

## ワークフロー

### Step 1: Issueの読み取り

```bash
# URLから owner/repo と issue番号を抽出、または現在のリポジトリのIssue番号を使用
gh issue view <number> --repo <owner/repo> --json title,body,labels,assignees,comments
```

Issue本文、コメント、ラベルからコンテキストを把握する。

### Step 2: コードベースの調査

Issueの内容に基づき、関連するコードを調査する:

- 言及されているファイル・関数・エラーメッセージを検索
- 再現手順があれば該当箇所を特定
- 影響範囲を確認

### Step 3: 対応方針のプラン

Planモードに入り、対応方針を策定する。以下を含める:

- **問題の要約**: Issueの本質
- **原因の仮説**: 調査結果に基づく
- **対応ステップ**: 具体的な変更内容
- **テスト方針**: 修正の検証方法

ユーザーの承認を得てから実装に進む。

### Step 4: 実装

プランに従ってコードを修正する。修正が完了したら:

1. テストがあれば実行して通ることを確認
2. gitmojiを使ってコミット（コミットメッセージに `Fixes #<number>` を含める）
3. プッシュ

```bash
git commit -m "🐛 fix: <修正内容の説明>

Fixes #<issue_number>"
git push
```

### Step 5: Issueのクローズ

PRを経由せず直接mainにプッシュした場合、`Fixes #N` で自動クローズされないため手動でクローズする:

```bash
gh issue close <number> --repo <owner/repo> --comment "✅ 対応完了

<対応内容のサマリー>"
```

PRを作成した場合は、マージ時に `Fixes #N` により自動クローズされる。

### Step 6: サマリー表示

```
✅ Issue #<number> を解決しました

- Issue: <title>
- 対応: <修正内容の要約>
- コミット: <commit hash>
```
