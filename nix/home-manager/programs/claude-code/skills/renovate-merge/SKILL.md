---
name: renovate-merge
version: 1.0.0
description: "Find Renovate PRs in the current repo, rebase, wait for CI, and merge them one by one. File an issue and skip if a PR is problematic."
---

# renovate-merge

Automatically process all open Renovate PRs in the current repository: rebase, wait for CI, and merge. If a PR has issues, file a GitHub Issue and skip it.

## Arguments

- Optional: `owner/repo` — target repository (defaults to current directory's repo)

## Behavior

### Step 1: List Renovate PRs

```bash
gh pr list --author "app/renovate" --state open --json number,title,headRefName,url --limit 100
```

If no PRs found, report "No open Renovate PRs" and exit.

### Step 2: Process each PR sequentially

For each PR, run the following steps. **Process one PR at a time** because rebasing one may affect others.

#### 2a: Check PR mergeability and CI status

```bash
gh pr view <NUMBER> --json mergeable,statusCheckRollup,title,url,headRefName
```

If `mergeable` is `CONFLICTING`, skip to Step 2e (file issue).

#### 2b: Rebase the PR

Use the GitHub API to trigger a rebase (update branch):

```bash
gh pr update-branch <NUMBER> --rebase
```

If rebase fails, skip to Step 2e (file issue).

#### 2c: Wait for CI to complete

Poll CI status in the background. Check every 30 seconds, timeout after 15 minutes:

```bash
gh pr checks <NUMBER> --watch --fail-fast
```

Run this command with the Bash tool's `run_in_background` option, then wait for the notification.

#### 2d: Merge the PR

If all checks pass:

```bash
gh pr merge <NUMBER> --squash --auto --delete-branch
```

Report success: `Merged: <TITLE> (#<NUMBER>)`

Then proceed to the next PR.

#### 2e: File issue and skip

If rebase fails, CI fails, or the PR is otherwise problematic:

1. Collect error details (CI failure logs, conflict info, etc.)
2. Create a GitHub Issue:

```bash
gh issue create \
  --title "Renovate: <PR_TITLE> のマージに失敗" \
  --body "$(cat <<'ISSUE_EOF'
## 概要

Renovate PR #<NUMBER> の自動マージに失敗しました。

**PR**: <PR_URL>
**ブランチ**: `<BRANCH>`

## 失敗理由

<REASON_DETAIL>

## 対応

手動での確認・対応が必要です。

- [ ] 変更内容を確認
- [ ] 破壊的変更がある場合はコード修正
- [ ] CI通過を確認してマージ

---
*This issue was automatically created by `renovate-merge` skill.*
ISSUE_EOF
)"
```

3. Report: `Skipped: <TITLE> (#<NUMBER>) — Issue #<ISSUE_NUMBER> filed`
4. Proceed to the next PR.

### Step 3: Summary

After processing all PRs, output a summary:

```
## Renovate PR Processing Complete

- Merged: N PRs
- Skipped: M PRs (issues filed)

### Merged
- <TITLE> (#<NUMBER>)
- ...

### Skipped
- <TITLE> (#<NUMBER>) → Issue #<ISSUE_NUMBER>
- ...
```

## Notes

- Always process PRs sequentially — merging one may cause conflicts in others
- Use `--squash` merge to keep history clean
- The `--auto` flag enables auto-merge when checks pass, so if `gh pr merge` returns before checks complete, it will merge automatically once they do
- If `gh pr update-branch --rebase` is not available (repo settings), try `gh pr comment <NUMBER> --body "@renovatebot rebase"` as a fallback and wait 60 seconds
- Timeout for CI: 15 minutes per PR. If exceeded, file an issue and skip.
