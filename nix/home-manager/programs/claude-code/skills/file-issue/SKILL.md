---
name: file-issue
version: 1.0.0
description: "File a GitHub Issue for a discovered problem that is out of scope for the current task, then move on."
---

# File Issue Skill

作業中に発見した、今回のタスクとは直接関係ない問題をGitHub Issueに起票し、その場では対応しない。

## 引数

- 問題の説明（自然言語）。省略時は会話コンテキストから推測する。

## ワークフロー

### Step 1: 対象リポジトリの特定

以下の優先順位でリポジトリを決定する:

1. **会話コンテキスト**: 問題がどのリポジトリに属するか（議論中のファイルパス、言及されたプロジェクト名など）から判断
2. **カレントディレクトリ**: `git remote get-url origin` から取得

判断に迷う場合はユーザーに確認する。

### Step 2: Issueの内容を構成

会話コンテキストと問題の説明から以下を作成:

- **タイトル**: 簡潔に問題を要約（日本語）
- **本文**: 以下の構成で記述

```markdown
## 概要
（問題の説明）

## 発見の経緯
（どの作業中に発見されたか）

## 再現手順 / 該当箇所
（わかる範囲で記載）

## 期待される動作
（あれば記載）

---
🤖 このIssueはClaude Codeによって自動起票されました
```

### Step 3: ユーザーに確認

起票内容をユーザーに提示し、承認を得る。修正があれば反映する。

### Step 4: Issue作成

```bash
gh issue create --repo <owner/repo> --title "<title>" --body "<body>"
```

### Step 5: 元の作業に戻る

```
✅ Issue #<number> を作成しました: <issue-url>
引き続き元のタスクを進めます。
```

元の作業に集中を戻し、起票した問題には対応しない。
