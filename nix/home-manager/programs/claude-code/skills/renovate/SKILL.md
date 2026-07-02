---
name: renovate
version: 1.0.0
description: "Process Renovate PRs in a repo: rebase, wait for CI, merge. If CI fails, analyze and attempt a fix (max 2 tries), always reporting every fix as a PR comment and in the final summary. File an issue and skip if unfixable."
---

# renovate

指定リポジトリの open な Renovate PR を1件ずつ処理する: rebase → CI 待ち → 通れば merge。
CI が落ちたら**原因を分析してコード修正を試みる**（旧 renovate-merge との差分）。
**加えた修正は必ずレポートする** — PR コメントと最終サマリの両方に残すこと。修正したのに報告しない、は許されない。

## Arguments

- 任意: `owner/repo` — 対象リポジトリ。省略時はカレントディレクトリの repo。
  以降のすべての `gh` コマンドに `-R <owner/repo>` を付けること（省略時は不要）。

## Behavior

### Step 1: Renovate PR を列挙

```bash
gh pr list --author "app/renovate" --state open -R <owner/repo> \
  --json number,title,headRefName,url,labels --limit 100
```

無ければ「No open Renovate PRs」と報告して終了。

### Step 2: PR を1件ずつ順次処理

**必ず逐次処理**。1件 merge / rebase すると他 PR の状態が変わるため、並行処理しない。

各 PR について:

#### 2a: mergeability / CI 状態を確認

```bash
gh pr view <NUMBER> --json mergeable,statusCheckRollup,title,url,headRefName
```

`mergeable` が `CONFLICTING` なら 2-fix へ（conflict も修正対象。lockfile だけの conflict なら
rebase 後の lockfile 再生成で直ることが多い）。手に負えなければ 2-issue へ。

#### 2b: rebase

```bash
gh pr update-branch <NUMBER> --rebase
```

失敗したら fallback: `gh pr comment <NUMBER> --body "@renovatebot rebase"` を投稿して 60 秒待つ。
それでもダメなら 2-fix へ。

#### 2c: CI 完了を待つ

```bash
gh pr checks <NUMBER> --watch --fail-fast
```

Bash tool の `run_in_background` で実行し、完了通知を待つ。timeout は **15分/PR**。
timeout したら 2-issue へ。

#### 2d: merge

CI が全部通ったら:

```bash
gh pr merge <NUMBER> --squash --auto --delete-branch
```

`Merged: <TITLE> (#<NUMBER>)` と報告して次の PR へ。

### Step 2-fix: CI 失敗時の修正ループ（最大2回試行）

CI が落ちた PR は issue 化してスキップする前に、修正を試みる。

#### fix-1: 失敗ログを取得して原因を特定

```bash
gh pr checks <NUMBER> --json name,state,link
gh run view <RUN_ID> --log-failed -R <owner/repo>
```

典型的な原因パターン:
- **lockfile 不整合** → lockfile を再生成して commit
- **型エラー / API の破壊的変更** → 依存の changelog / migration guide を確認して呼び出し側を修正
- **テスト失敗** → 新バージョンの挙動変化に合わせてテストまたは実装を修正
- **lint / format** → lint fix を実行
- **flaky に見える失敗** → 1回だけ re-run (`gh run rerun <RUN_ID> --failed`) して様子を見る（これは試行回数に数えない）

#### fix-2: ローカルに PR ブランチを用意

1. `~/Projects/` 配下に既存 clone があればそれを使う（`ls ~/Projects/ | grep <repo>` 等で探す）。
   作業中の変更を壊さないよう `git status` を確認し、dirty なら `git stash` してから進める（終了時に戻す）。
2. 無ければ scratchpad に一時 clone: `gh repo clone <owner/repo> <scratchpad>/renovate-<repo>`
3. `gh pr checkout <NUMBER>` でブランチを取得。

#### fix-3: 修正して push

- 修正は**最小限**。失敗の原因に直結する変更のみ。ついでのリファクタ・整形はしない。
- push 前に `git diff` を確認する。
- コミットメッセージは何をなぜ直したか分かるように書く
  （例: `fix: eslint v9 の flat config 移行に伴い .eslintrc を eslint.config.js へ変換`）。
- `--no-verify` は使わない。
- `git push` で PR ブランチへ push。

#### fix-4: 修正をレポート（必須・スキップ禁止）

push したら**すぐに** PR コメントを投稿する:

```bash
gh pr comment <NUMBER> --body "$(cat <<'COMMENT_EOF'
🤖 **renovate skill が CI 失敗を自動修正しました**

## 原因
<CI がなぜ落ちたか — ログの要点を引用>

## 修正内容
<変更したファイルと内容の要約。diff の要点>

## 判断根拠
<なぜこの修正で正しいと判断したか — changelog / migration guide への言及など>

---
*この修正は自動で行われました。マージ前に内容を確認してください。*
COMMENT_EOF
)"
```

同時に、最終サマリ用に「PR番号 / 原因 / 修正内容 / 修正コミット SHA」を記録しておく。

#### fix-5: CI を再度待つ

2c と同様に `gh pr checks --watch`。通れば 2d (merge) へ。
落ちたら試行 2 回目として fix-1 から繰り返す。**2 回試して直らなければ 2-issue へ**。

### Step 2-issue: 修正不能ならスキップ

```bash
gh issue create -R <owner/repo> \
  --title "Renovate: <PR_TITLE> のマージに失敗" \
  --body "$(cat <<'ISSUE_EOF'
## 概要

Renovate PR #<NUMBER> の自動マージに失敗しました。

**PR**: <PR_URL>
**ブランチ**: `<BRANCH>`

## 失敗理由

<REASON_DETAIL — CI ログの要点>

## 試みた修正

<自動修正を試みた場合はその内容と、なぜ解決しなかったか。試みていなければ「なし（<理由>）」>

## 対応

手動での確認・対応が必要です。

- [ ] 変更内容を確認
- [ ] 破壊的変更がある場合はコード修正
- [ ] CI通過を確認してマージ

---
*This issue was automatically created by the `renovate` skill.*
ISSUE_EOF
)"
```

`Skipped: <TITLE> (#<NUMBER>) — Issue #<ISSUE_NUMBER> filed` と報告して次の PR へ。

### Step 3: 最終サマリ（必須）

全 PR 処理後、必ず以下の形式でサマリを出力する。**自動修正した PR が 1 件でもあれば「自動修正の詳細」セクションは省略不可**。

```
## Renovate 処理完了 (<owner/repo>)

- Merged: N 件（うち自動修正 K 件）
- Skipped: M 件（issue 化）

### Merged
- <TITLE> (#<NUMBER>)
- <TITLE> (#<NUMBER>) ← 自動修正あり

### 自動修正の詳細
- #<NUMBER>: <原因の1行要約>
  → 修正: <変更ファイルと内容> (commit <SHA>)
  → PR コメント: <コメント URL>

### Skipped
- <TITLE> (#<NUMBER>) → Issue #<ISSUE_NUMBER>
```

## Notes

- **逐次処理を厳守** — 1件の merge が他 PR の conflict / CI 状態を変える
- merge は `--squash`。`--auto` を付けているので checks 完了前に merge コマンドが返っても、通過後に自動 merge される
- 修正の試行は **最大2回/PR**、CI 待ちは **15分/PR**。超えたら issue 化してスキップ
- 既存 clone を使った場合、終了時に元のブランチへ戻し、stash していれば pop する
- 一時 clone した場合は scratchpad なので掃除不要
- major バージョンアップの PR は特に慎重に。changelog を確認し、修正の確信が持てなければ無理に直さず issue 化する
