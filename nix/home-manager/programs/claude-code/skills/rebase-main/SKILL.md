---
name: rebase-main
version: 1.0.0
description: "Fetch latest main and rebase current branch onto it. Use to keep a feature branch up to date."
---

# Rebase onto Main Skill

最新のmainをfetchし、現在のブランチをrebaseする。

## ワークフロー

### Step 1: 現在のブランチを確認

```bash
git branch --show-current
```

mainブランチにいる場合はrebase不要なので中止する。

### Step 2: 未コミットの変更を確認

```bash
git status --short
```

未コミットの変更がある場合はユーザーに確認してから続行する（stashするか、コミットするか）。

### Step 3: 最新のmainをfetch

```bash
git fetch origin main
```

### Step 4: rebase

```bash
git rebase origin/main
```

コンフリクトが発生した場合:
1. コンフリクトの内容をユーザーに報告
2. 解決方針を提案
3. ユーザーの承認を得てから解決
4. `git add <resolved-files> && git rebase --continue` で続行

### Step 5: force push

rebaseによりコミット履歴が変わるため、`--force-with-lease` でpush:

```bash
git push --force-with-lease
```

### Step 6: サマリー表示

```
## Rebase 完了

- ブランチ: <branch-name>
- ベース: main (<commit hash>)
- プッシュ済み: Yes/No
```
