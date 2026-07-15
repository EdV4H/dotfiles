---
name: renovate
version: 1.0.0
description: "Process Renovate PRs in a repo without blocking on CI: rebase/resolve conflicts, and if CI is currently failing attempt one fix, then approve and enable GitHub auto-merge (CI gates the actual async merge). Report every fix as a PR comment and in the summary. Runs headless (claude -p). Skip majors and unfixable PRs to an issue."
---

# renovate

指定リポジトリの open な Renovate PR を1件ずつ処理する: rebase / conflict 解消 →
CI が今 fail なら**原因を分析して1回修正** → approve して **GitHub の auto-merge を有効化**。
**CI は待たない**（`claude -p` の one-shot でも全 PR を捌けるようにするため）。実際のマージは
CI 緑化時に GitHub が非同期で行う。CI がまだ緑でない PR は次回 run で再評価される。
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

**CI を同期的に待たない**。この skill は `claude -p`（headless・one-shot）でも走る。
`gh pr checks --watch` でブロックすると one-shot 実行が最初の CI 待ちで力尽きて終了し、
何も進まない。代わりに各 PR で「rebase → 必要なら修正 → approve → auto-merge を有効化」
までを**待たずに**やり、**実際のマージは GitHub の auto-merge（CI 緑化時に非同期実行）に委ねる**。
CI がまだ赤い/未完の PR は次回 run で再評価される（放置で徐々に片付く）。

各 PR について。**順序が重要**: 先に「ベースへの追従（rebase / conflict 解消）」を完了させ、
CI がその最新 head に対して走る状態にしてから、現在の CI 状態を**スナップショットで**評価する。
古い（rebase 前の）CI run を見て失敗診断に入ってはいけない。

#### 2a: mergeability を確認（CI 評価より先）

```bash
gh pr view <NUMBER> -R <owner/repo> --json mergeable,mergeStateStatus,baseRefName,statusCheckRollup,title,url,headRefName,labels,commits
```

まず `mergeable` を見る:

- **`CONFLICTING` / `mergeStateStatus: DIRTY`** → **2b でコンフリクト解消が最優先**。
  ⚠️ ベースとコンフリクトしている PR は GitHub がテスト用マージコミットを作れず、
  **`pull_request` トリガーの CI（テスト等）が走らない**。`statusCheckRollup` に出ている
  失敗は rebase 前の古い run なので、それを見て 2-fix に入るのは誤り。先に解消する。
- `MERGEABLE` / `UNKNOWN` → 2b へ。

#### 2b: ベースへ追従（rebase / conflict 解消）

```bash
gh pr update-branch <NUMBER> -R <owner/repo> --rebase
```

- 成功 or 「already up to date」→ 2c へ。
- **conflict で失敗する場合**（`Cannot update PR branch due to conflicts`）→ ローカルで解消:
  1. fix-2 の要領で対象 repo を用意（**フル clone 推奨**。shallow / single-branch だと
     ベースブランチへの rebase が不安定）。ベースブランチ（例 `develop`）も fetch する。
  2. `git rebase origin/<baseRef>`。コンフリクトが **lockfile のみ**なら、ソース側
     （package.json / catalog）の conflict を解消 → `pnpm install --lockfile-only` で
     lockfile を再生成（手で lockfile をマージしない）。
  3. commit に修正マーカー `[renovate-auto-fix]` を含め、push（force-with-lease）。
- `update-branch` 自体が使えない repo なら fallback: `@renovatebot rebase` コメント。
- 解消の見込みが立たなければ 2-issue へ。

rebase / push した直後は**待たない**。2c で現在の CI 状態だけ見る。

#### 2c: 現在の CI 状態をスナップショット評価（待たない）

`--watch` は使わない。今の状態だけ取る:

```bash
gh pr checks <NUMBER> -R <owner/repo>
```

- **全て pass** → 2d（approve + auto-merge。CI 緑なので即マージされる）。
- **pending / まだ走り出していない** → 2d（approve + `--auto` を有効化。GitHub が緑化時に自動マージ）。
  ⚠️ ただし rebase 直後で `pull_request` CI がまだ起動していないだけかもしれない。
  その場合も approve + `--auto` にしておけば、CI が緑になった時点で GitHub がマージする。待たない。
- **fail** → 2-fix へ（ただし再修正ループ防止ガードあり。下記参照）。

#### 2d: approve → auto-merge 有効化（待たない）

Renovate PR は作者が bot（`app/renovate`）で自分の PR ではないので approve してよい:

```bash
gh pr review <NUMBER> -R <owner/repo> --approve \
  --body "Auto-approved by renovate skill (CI gates the actual merge)."
gh pr merge <NUMBER> -R <owner/repo> --squash --auto --delete-branch
```

- `--auto` は **CI が全部緑になった時点で GitHub がマージ**する。緑なら即、pending なら後で自動。
  **skill 側は待たない**。approve は CI を無効化しない（`--auto` は必須チェック通過が前提）ので、
  CI 未完でも先に approve + auto-merge しておくのは安全。
- **merge method のフォールバック**: repo の ruleset が squash を拒否する場合
  （`Merge method ... is not allowed` 等のエラー）、`--merge` → `--rebase` の順で
  試す。どれか許可されている方式を使えばよい（`--delete-branch` はそのまま）。
- **major バージョンアップは自動 approve しない**。2-issue で人間に回す
  （無人で破壊的変更を本番に入れない）。minor / patch のみ auto-approve 対象。
  major/minor/patch は PR タイトル（`to vN` / `to vN.M`）や `labels` から判定する。
- `Queued for auto-merge: <TITLE> (#<NUMBER>)` と報告して次の PR へ。

### Step 2-fix: CI 失敗時の修正（1回 / 再修正ループ防止）

CI が**現在 fail** の PR は issue 化する前に修正を試みる。ただし one-shot・複数 run に
またがるため、**同じ PR を毎 run 直し続けない**ガードを最初に効かせる:

- **再修正ループ防止**: HEAD commit のメッセージに既に `[renovate-auto-fix]` が入っていて
  かつ CI がまだ fail なら、**前回の自動修正が効かなかった** ということ。もう直さず 2-issue へ。
- flaky が疑われる時のみ `gh run rerun <RUN_ID> --failed` を1回（これは修正に数えない）。
- それ以外（まだ自分が直していない fail）なら以下で1回だけ修正を試みる。

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
- コミットメッセージは何をなぜ直したか分かるように書き、**必ずマーカー
  `[renovate-auto-fix]` を含める**（次回 run の再修正ループ防止に使う）
  （例: `fix: eslint v9 flat config 移行に伴い設定を変換 [renovate-auto-fix]`）。
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

#### fix-5: approve + auto-merge して次へ（待たない）

修正 push 後は **CI を待たない**。2d と同じく approve + `--auto` merge を有効化し、次の PR へ進む。
GitHub が CI 緑化時にマージする。もし修正が不十分で CI が再び赤なら、次回 run の 2-fix 冒頭の
「再修正ループ防止」ガードが検知し（HEAD が `[renovate-auto-fix]` かつ fail）、その時に 2-issue へ回す。
このため 1 run 内では **1 PR につき修正は1回**まで。

### Step 2-issue: 修正不能ならスキップ（重複 issue を作らない）

**まず既存の open issue を必ず確認する**。同じ PR に対して毎 run 新規 issue を量産しないため、
issue 本文には機械可読マーカー `<!-- renovate-skill-pr-<NUMBER> -->` を必ず入れ、
作成前にそのマーカーで既存 open issue を探す。検索インデックスのラグ/クォート事故を避けるため、
`--search` ではなく **open issue を列挙して body をローカル照合**する:

```bash
EXISTING=$(gh issue list -R <owner/repo> --state open --limit 200 --json number,body \
  --jq '[.[] | select(.body | contains("renovate-skill-pr-<NUMBER>"))][0].number // empty')
```

- **既存があれば新規作成しない**。その issue に今回の失敗内容をコメント追記するだけ:
  ```bash
  gh issue comment "$EXISTING" -R <owner/repo> --body "再試行も失敗（<日付/CI要点>）。<試した修正と結果>"
  ```
  報告は `Skipped: <TITLE> (#<NUMBER>) — 既存 Issue #$EXISTING に追記` とする。
- **無ければ**新規作成（本文にマーカーを必ず含める）:

```bash
gh issue create -R <owner/repo> \
  --title "Renovate: <PR_TITLE> のマージに失敗" \
  --body "$(cat <<'ISSUE_EOF'
<!-- renovate-skill-pr-<NUMBER> -->
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
skill は待たないので「Merged」ではなく「auto-merge に載せた（Queued）」を報告する
（実際のマージは後で GitHub が CI 緑化時に行う）。

```
## Renovate 処理 (<owner/repo>)

- Queued for auto-merge: N 件（うち自動修正 K 件）  ← approve + --auto 済み。CI 緑で自動マージ
- Skipped: M 件（issue 化 / major など）

### Queued
- <TITLE> (#<NUMBER>)
- <TITLE> (#<NUMBER>) ← 自動修正あり

### 自動修正の詳細
- #<NUMBER>: <原因の1行要約>
  → 修正: <変更ファイルと内容> (commit <SHA>)
  → PR コメント: <コメント URL>

### Skipped
- <TITLE> (#<NUMBER>) → Issue #<ISSUE_NUMBER> / major のため人間確認
```

## Notes

- **CI を待たない** — `--watch` は禁止。approve + `--auto` merge を有効化して次へ進み、
  実際のマージは GitHub の auto-merge（CI 緑化時に非同期実行）に委ねる。これにより
  `claude -p`（one-shot）でも全 PR を1回で捌ける。緑でない PR は次回 run で再評価
- **再修正ループ防止** — 修正 commit には必ず `[renovate-auto-fix]` マーカーを付ける。
  次回 run で「HEAD が `[renovate-auto-fix]` かつ CI 依然 fail」なら再修正せず issue 化。
  1 run 内では 1 PR につき修正は 1 回まで
- **rebase → CI 状態確認 → 診断 の順序を守る** — コンフリクトした PR では `pull_request` 系 CI が走らない。
  Labeler など `pull_request_target` 系だけ緑でも、テストが走っていないだけのことがある。
  `statusCheckRollup` の失敗が「今の head の結果か rebase 前の古い run か」を必ず区別する
- **逐次処理を厳守** — 1件の rebase/merge が他 PR の conflict / CI 状態を変える
- 既存 clone を使った場合、終了時に元のブランチへ戻し、stash していれば pop する
- 一時 clone した場合は scratchpad なので掃除不要
- major バージョンアップの PR は特に慎重に。自動 approve せず issue 化して人間に回す
