---
name: post-merge
version: 1.0.0
description: "Post-merge cleanup: switch to main, pull latest, and delete the merged branch. Use after merging a PR."
---

# Post-Merge Cleanup Skill

PRマージ後にmainブランチに戻り、最新を取得し、マージ済みブランチを削除する。

## ワークフロー

### Step 1: 現在のブランチを確認

```bash
git branch --show-current
```

現在のブランチ名を記録する（後で削除対象として使う）。
mainにいる場合はStep 2のcheckoutをスキップ。

### Step 2: 未コミットの変更を確認

```bash
git status --short
```

未コミットの変更がある場合はユーザーに確認してから続行する（stashするか、破棄するか）。

### Step 3: mainに切り替えて最新を取得

```bash
git checkout main
git pull origin main
```

### Step 4: マージ済みブランチの削除

Step 1で記録したブランチがmain以外であれば、ローカルブランチを削除:

```bash
git branch -d <branch-name>
```

`-d`（小文字）を使うことで、マージされていないブランチの誤削除を防ぐ。

リモートブランチも削除されていなければ削除を提案（GitHub PRマージ時に自動削除されている場合が多い）:

```bash
# リモートブランチの存在確認
git ls-remote --heads origin <branch-name>

# 存在する場合、ユーザーに確認してから削除
git push origin --delete <branch-name>
```

### Step 5: サマリー表示

```
## Post-Merge Cleanup 完了

- ブランチ: main (最新)
- 削除したブランチ: <branch-name>
- 最新コミット: <commit hash> <commit message>
```

### Step 6: コンテキスト削減

タスク完了後、`/compact` を実行してコンテキストを圧縮する。
post-mergeは区切りのタイミングなので、不要な履歴を積極的に削減する。
