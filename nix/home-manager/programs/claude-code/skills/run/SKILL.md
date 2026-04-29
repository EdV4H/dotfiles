---
name: run
version: 1.0.0
description: "Run a command in the background in the current working directory. In a worktree, copies .env files from main repo if missing."
---

# run

引数で指定されたコマンドを、作業中のディレクトリでバックグラウンド実行する。

## 引数

- `args`: 実行するコマンド（例: `/run npm test`, `/run make build`）

## Behavior

### Step 1: 作業ディレクトリの決定

```bash
pwd
git rev-parse --git-common-dir 2>/dev/null
```

- worktree内であればそのworktreeのディレクトリ（`pwd`）で実行
- 通常のリポジトリであればカレントディレクトリで実行

### Step 2: worktreeの場合、.envファイルをコピー

worktree内で作業している場合（`git rev-parse --git-common-dir` がメインリポジトリの `.git` を指す場合）:

```bash
MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}')
WORKTREE_DIR=$(pwd)
```

メインリポジトリの `.env*` ファイルのうち、worktreeに存在しないものをコピーする:

```bash
for envfile in $(find "$MAIN_REPO" -maxdepth 3 -name '.env*' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.claude/*' 2>/dev/null); do
  REL_PATH="${envfile#$MAIN_REPO/}"
  if [ ! -f "$WORKTREE_DIR/$REL_PATH" ]; then
    mkdir -p "$WORKTREE_DIR/$(dirname "$REL_PATH")"
    cp "$envfile" "$WORKTREE_DIR/$REL_PATH"
  fi
done
```

コピーしたファイルがあれば報告する。

### Step 3: コマンドをバックグラウンドで実行

Bashツールの `run_in_background: true` を使用して、引数で渡されたコマンドを実行する。

```bash
# argsの内容をそのまま実行
<args>
```

### Step 4: 実行開始を報告

以下を簡潔に報告:
- 実行したコマンド
- 実行ディレクトリ
- コピーした.envファイル（あれば）
- 「バックグラウンドで実行中。完了したら通知します。」

## 注意事項

- コマンドの完了を待たない — バックグラウンドで実行して即座に制御を返す
- `.env` ファイルは**存在しない場合のみ**コピー（既存ファイルを上書きしない）
- `.env` ファイルのコピーはworktree内でのみ行う（通常リポジトリではスキップ）
