# PR ワークフロー自動化

> PR の作成から CI 監視、auto-merge、worktree クリーンアップまでを一連のスキルで自動化する。

## 課題

PR 作成の手順が多い: 変更のコミット分割、PR 作成、Copilot レビュー依頼、CI 待機、auto-merge 有効化、レビュワー追加。毎回同じ手順を手動で繰り返していた。

## 解決策

4つのスキル/コマンドを組み合わせて、PR ライフサイクル全体をカバーする:

```
┌─────────────┐    ┌────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ /pull-request│───▶│ /update-pr │───▶│ /renovate-merge  │    │/worktree-cleanup │
│  PR 作成     │    │  PR 更新    │    │  依存関係更新     │    │  後片付け         │
└─────────────┘    └────────────┘    └──────────────────┘    └──────────────────┘
```

## スキル詳細

### `/pull-request` — PR の作成

コマンド（`~/.claude/commands/pull-request.md`）として定義。

```
/pull-request
```

**処理フロー**:
1. `git status` / `git diff` で変更を分析
2. 変更を論理単位でグルーピング（機能/テスト/リファクタ/ドキュメント）
3. 各グループを個別にコミット（1コミット1目的）
4. リモートにプッシュ
5. `gh pr create` で PR 作成
6. Copilot にレビュー依頼 → レビューコメント対応
7. `gh pr checks --watch` で CI 監視
8. CI 通過後に `gh pr merge --auto` で auto-merge 有効化
9. 人間のレビュワーを追加

**Changeset 対応**: `.changeset/` ディレクトリがあるモノレポでは、自動で changeset を作成・コミットする。

### `/update-pr` — 既存 PR の更新

```
/update-pr          # 現在のブランチの PR を自動検出
/update-pr 42       # PR #42 を指定
```

**処理フロー**:
1. 現在のブランチに紐づく PR を特定
2. 変更を分析して論理単位でコミット分割
3. プッシュ
4. PR タイトル/説明を必要に応じて更新
5. Copilot レビュー再依頼 + CI 監視
6. auto-merge 有効化

**更新判断**: スコープが変わった場合はタイトル・説明を更新、typo 修正程度なら更新しない。

### `/renovate-merge` — Renovate PR 一括処理

```
/renovate-merge
```

**処理フロー**:
1. `gh pr list --author "app/renovate"` で対象 PR を取得
2. 各 PR を**順番に**処理（並行だと rebase 競合が起きる）
3. rebase → CI 待機（15分タイムアウト） → squash merge
4. 失敗した PR は GitHub Issue を作成してスキップ

**出力例**:
```
## Renovate PR Processing Complete
- Merged: 5 PRs
- Skipped: 1 PR (issues filed)

### Merged
- Update typescript to v5.4 (#123)
- Update eslint to v9.1 (#124)
...

### Skipped
- Update react to v19 (#125) → Issue #130
```

### `/worktree-cleanup` — Worktree のクリーンアップ

```
/worktree-cleanup
```

**処理フロー**:
1. 未コミット変更の確認（コミット/stash/破棄/中止を選択）
2. PR の状態確認（マージ済みか）
3. worktree 削除 + ブランチ削除（ローカル+リモート）
4. main を最新に更新
5. オプション: 次の worktree を作成（`.env` 自動コピー付き）

## 典型的なワークフロー

### 新機能開発

```bash
# 1. worktree を作成して作業開始
git worktree add .claude/worktrees/feature-x -b feature/awesome

# 2. 実装...

# 3. PR 作成
/pull-request

# 4. レビュー指摘対応
# ... コード修正 ...
/update-pr

# 5. マージ後にクリーンアップ
/worktree-cleanup
```

### 週次の依存関係更新

```bash
# Renovate PR を一括処理
/renovate-merge
```

## 主要ファイル

| ファイル | 役割 |
|---------|------|
| `~/.claude/commands/pull-request.md` | PR 作成コマンド |
| [`skills/update-pr/SKILL.md`](../../nix/home-manager/programs/claude-code/skills/update-pr/SKILL.md) | PR 更新スキル |
| [`skills/renovate-merge/SKILL.md`](../../nix/home-manager/programs/claude-code/skills/renovate-merge/SKILL.md) | Renovate PR 処理スキル |
| [`skills/worktree-cleanup/SKILL.md`](../../nix/home-manager/programs/claude-code/skills/worktree-cleanup/SKILL.md) | Worktree クリーンアップスキル |

## カスタマイズ

### マージ戦略の変更

デフォルトは `--squash` マージ。通常のマージコミットを使いたい場合:

```markdown
# SKILL.md 内
gh pr merge <NUMBER> --merge --auto --delete-branch
```

### CI タイムアウトの変更

`/renovate-merge` の CI 待機は 15 分。変更する場合は SKILL.md の記述を修正。

### Copilot レビューを無効化

`/pull-request` の Step 6 を削除すれば Copilot レビュー依頼をスキップできる。

## Tips & 注意点

- **auto-merge の前提条件**: リポジトリの Settings → General で "Allow auto-merge" が有効である必要がある
- **Copilot レビュー**: GitHub Copilot のレビュー機能が有効なリポジトリでのみ動作。無効なリポジトリでは API コールが失敗するがスキップされる
- **force push の安全性**: `/update-pr` は force push が必要な場合、必ずユーザーに確認してから `--force-with-lease` を使う
- **Renovate の順序**: `/renovate-merge` は PR を1つずつ処理する。これは rebase 後に他の PR のベースが変わるため。並行処理すると高確率でコンフリクトする
