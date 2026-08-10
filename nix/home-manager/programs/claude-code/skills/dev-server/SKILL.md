---
name: dev-server
version: 1.0.0
description: "Start / inspect / stop long-running dev servers (Vite, pnpm dev, Next, etc.) inside a zellij pane or tab so they survive. Use this INSTEAD of `!`-backgrounding or run_in_background for any process that must keep running — the Claude Code harness reaps those with SIGTERM (exit 143) after ~20min. Commands: dev-up / dev-logs / dev-down / dev-list."
---

# dev-server

長時間走らせる開発サーバー（`pnpm dev` / Vite / Next / watch 系）を **zellij の
ペイン・タブの中**で起動する。これらは zellij server の子プロセスになり、Claude
Code ハーネスのプロセスツリーから外れるので **SIGTERM(143) で回収されない**。

## いつ使うか（重要）

**終わらないプロセスは `!` でも `run_in_background` でも起動しない。** それらは
ハーネスの子なので一定時間後に SIGTERM(exit 143) で kill される（Vite の HMR が
正常でも約20分で落ちる事象が確認済み）。dev サーバー・watcher・常駐プロセスは
**必ず `dev-up`** を使うこと。

対象の目安:
- `pnpm dev` / `pnpm dev:proxy` / `vite` / `next dev` / `astro dev` など常駐サーバー
- `tsc --watch` / `vitest --watch` など終わらない watch タスク

`npm test`（一回で終わる）や `pnpm build` のような**有限のコマンドは対象外** —
通常どおり Bash ツールで実行してよい。

## コマンド

前提: **zellij セッションの中**で動くこと（`$ZELLIJ` が必要）。ペイン ID は zellij
が管理し、停止はプロセスグループごと kill するので focus 奪取や事故的な
close-pane は起きない。

### 起動

```bash
dev-up [--keep] [--stack|--tab|--float|--split] <name> -- <cmd...>
```

- `<name>` は識別名（`[A-Za-z0-9._-]` のみ）。ログ・停止・一覧のキーになる。
- 配置（省略時 `--stack`）:
  - `--stack` 現在タブにスタックペインで追加（デフォルト）
  - `--tab`   `dev:<name>` という新規タブ（起動後フォーカスは呼び出し元タブに戻る）
  - `--float` フローティングペイン
  - `--split` 現在ペインを分割
- `--keep`: **自動再起動の対象**にする（下記「自動再起動」参照）。
- **cwd は今いるディレクトリが使われる。** 別ディレクトリなら `cd` してから呼ぶ。

### 自動再起動（--keep + dev-supervise）

実際の dev サーバー（pnpm/vite/node）は、**起動してしばらくすると何かに SIGTERM(143)
で殺される**ことがある（tab/stack いずれでも起こりうる。trivial な sleep ループは
殺されないので、犯人は「サーバー」を狙っている）。対策として自動再起動を用意:

```bash
# 1) 見張り役を一度だけ起動（自分のタブで。trivial ループなので殺されない）
dev-up --tab supervisor -- dev-supervise

# 2) サーバーを --keep 付きで起動 → 死んでも watchdog が復活させる
dev-up --keep --tab weboard -- pnpm dev:proxy --filter weboard
```

- `dev-supervise` は `keep=1` のサーバーを ~15秒毎に監視し、pgid が死んでいたら
  `dev-up` で同じ cwd/コマンドで再起動する（元の argv を厳密に保存して復元）。
- 短時間に連続で死ぬ場合はレート制限（120秒に5回超で 300秒バックオフ）で暴走を防ぐ。
- `dev-down <name>` で keep マーカーごと消えるので、以後は再起動されない。
- `dev-supervise` 自体は多重起動しない（ロックあり）。稀に見張り役が消えたら再度
  `dev-up --tab supervisor -- dev-supervise` を叩く。

例:
```bash
cd ~/Projects/wevox/wevox-mono-web/web-progressive
dev-up weboard -- pnpm dev:proxy --filter weboard
```

### 状態確認（ログ）

ペインは画面外かもしれないので、**起動できたか / エラーが出ていないかは必ずログで確認する**:

```bash
dev-logs <name>          # 末尾60行（デフォルト）
dev-logs <name> 120      # 末尾120行
```

`dev-logs <name> -f`（follow）は**ブロックするのでヘッドレス／自動実行では使わない**。
起動直後は少し待ってから `dev-logs` を1回読むこと（"ready in xxx ms" 等を確認）。

### 停止

```bash
dev-down <name>
```

プロセスグループごと SIGTERM → 数百 ms 待って残っていれば SIGKILL → ペイン/タブを
ID 指定で除去する。

### 一覧

```bash
dev-list                 # 起動済み dev サーバーと alive/dead を表示
```

## 挙動メモ

- 出力は `/tmp/claude/dev-servers/<name>.log` に tee される（ペイン表示は維持）。
- state は `/tmp/claude/dev-servers/`（再起動で消える＝サーバーもどうせ止まるので整合）。
  `/tmp/claude` は Claude Code の Bash サンドボックス・実シェル・zellij ペインの
  **どこからでも書ける安定パス**なので採用している（`$TMPDIR` は文脈ごとに変わり
  dev-up と dev-down で食い違うため不可）。`DEV_SERVERS_DIR` で上書き可。
- pane はシェルを介さず起動されるため、`dev-up` を呼んだシェルの **PATH をそのまま
  pane に転送**している（mise/Homebrew/corepack の `pnpm`/`node` 等がそのまま解決する）。
  なので `dev-up` は **対象ツールが `pnpm` などを見つけられるシェル**で叩くこと。
- 同名が既に alive なら `dev-up` は起動を拒否する。まず `dev-down <name>`。
- 停止は必ず記録済み ID 経由。裸の `close-tab` / `close-pane` は使わない
  （CLAUDE.md の zellij close-tab 事故ルール準拠）。

## サンドボックスからの実行について（Claude 向け）

- `dev-logs` / `dev-list` / `dev-down`（stack/float/split）は state を読むだけ、または
  プロセスグループを kill するだけなので **Claude の Bash サンドボックスから動く**
  （停止は pgid kill → `--close-on-exit` でペイン自動消滅、zellij 操作は不要）。
- `dev-up` は `zellij action new-pane` を叩く。zellij クライアントは制御ソケットと
  ログを `$TMPDIR/zellij-<uid>/` に置くため、**サンドボックスの `$TMPDIR` が
  zellij サーバー起動時の `$TMPDIR` とズレていると "no active session" や
  logging の PermissionDenied で失敗する**ことがある。その場合は zellij サーバーと
  同じ `$TMPDIR`（通常 `/var/folders/.../T`）を export してから叩くか、ユーザーの
  実シェルで `dev-up` する。state パスは上記のとおり共有されるので、ユーザーが
  起動したサーバーも Claude 側から `dev-logs` / `dev-down` で監視・停止できる。
