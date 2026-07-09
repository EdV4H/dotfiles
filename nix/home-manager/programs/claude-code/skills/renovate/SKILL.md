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

各 PR について。**順序が重要**: 先に「ベースへの追従（rebase / conflict 解消）」を完了させ、
**CI が実際にその最新 head に対して走る状態**にしてから、CI 結果を評価・診断する。
古い（rebase 前の）CI run を見て失敗診断に入ってはいけない。

#### 2a: mergeability を確認（CI 評価より先）

```bash
gh pr view <NUMBER> --json mergeable,mergeStateStatus,baseRefName,statusCheckRollup,title,url,headRefName
```

まず `mergeable` を見る:

- **`CONFLICTING` / `mergeStateStatus: DIRTY`** → **2b でコンフリクト解消が最優先**。
  ⚠️ 重要: ベースとコンフリクトしている PR は GitHub がテスト用マージコミットを作れないため、
  **`pull_request` トリガーの CI（テスト等）が一切走らない**。この状態で `statusCheckRollup` に
  出ている失敗は **rebase 前の古い run** であり、それを見て 2-fix の原因診断に入るのは誤り。
  先にコンフリクトを解消して CI を走らせること。
- `MERGEABLE` / `UNKNOWN` → 2b へ（rebase で最新化してから CI を確定させる）。

#### 2b: ベースへ追従（rebase / conflict 解消）

```bash
gh pr update-branch <NUMBER> --rebase
```

- 成功 → 2c へ。
- **conflict で失敗する場合**（`Cannot update PR branch due to conflicts`）→ ローカルで解消:
  1. fix-2 の要領で対象 repo を用意（**フル clone 推奨**。shallow / single-branch だと
     ベースブランチへの rebase が不安定）。ベースブランチ（例 `develop`）も fetch する。
  2. `git rebase origin/<baseRef>`。コンフリクトが **lockfile のみ**なら、ソース側
     （package.json / catalog）の conflict を解消 → `pnpm install --lockfile-only` で
     lockfile を再生成（手で lockfile をマージしない）。
  3. push（force-with-lease）。ベースが速く動く repo では再 conflict しやすい点に留意。
- `update-branch` 自体が使えない repo なら fallback: `@renovatebot rebase` コメント → 60秒待つ。
- 解消の見込みが立たなければ 2-issue へ。

#### 2c: 最新 head に対する CI を確定させて待つ

rebase 後は **新しい head SHA に対して CI が新規に起動したこと**を確認してから待つ
（古い run の結果を使わない）。`pull_request` 系ワークフローが走っているかも確認する:

```bash
gh pr checks <NUMBER> --watch --fail-fast
```

Bash tool の `run_in_background` で実行し、完了通知を待つ。timeout は **15分/PR**。

- CI が全部 pass → 2d へ。
- 一部でも fail → 2-fix へ。
- 期待するチェック（テスト等）が起動していない場合、コンフリクト未解消や承認待ち
  （bot 作者 PR で `action_required`）を疑う。`gh run list --branch <BRANCH>` で状態確認。
- timeout したら 2-issue へ。

#### 2d: approve → merge

CI が全部通ったら、まず **review 要件を満たすため approve** する。Renovate PR は
作者が bot（`app/renovate`）で自分の PR ではないので、承認してよい:

```bash
gh pr review <NUMBER> -R <owner/repo> --approve \
  --body "CI green. Auto-approved by renovate skill."
gh pr merge <NUMBER> --squash --auto --delete-branch
```

- `REVIEW_REQUIRED` なリポジトリでも、この approve で `--auto` merge が走る（CI 緑が前提）。
- レビュー不要なリポジトリでは approve は無害（そのまま merge）。
- **ただし major バージョンアップは自動 approve しない**。CI が通っていても、
  自動 approve せず 2-issue で人間の確認に回す（破壊的変更を無人で本番に入れない）。
  minor / patch のみ自動 approve + merge の対象とする。

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

- **rebase → CI 確定 → 診断 の順序を守る** — コンフリクトした PR では `pull_request` 系 CI が走らない。
  Labeler など `pull_request_target` 系だけ緑になっていても、テストが走っていないだけのことがある。
  `statusCheckRollup` の失敗が「今の head の結果か、rebase 前の古い run か」を必ず区別する
- **逐次処理を厳守** — 1件の merge が他 PR の conflict / CI 状態を変える
- merge は `--squash`。`--auto` を付けているので checks 完了前に merge コマンドが返っても、通過後に自動 merge される
- 修正の試行は **最大2回/PR**、CI 待ちは **15分/PR**。超えたら issue 化してスキップ
- 既存 clone を使った場合、終了時に元のブランチへ戻し、stash していれば pop する
- 一時 clone した場合は scratchpad なので掃除不要
- major バージョンアップの PR は特に慎重に。changelog を確認し、修正の確信が持てなければ無理に直さず issue 化する
