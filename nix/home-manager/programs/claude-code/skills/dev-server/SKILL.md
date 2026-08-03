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
dev-up [--stack|--tab|--float|--split] <name> -- <cmd...>
```

- `<name>` は識別名（`[A-Za-z0-9._-]` のみ）。ログ・停止・一覧のキーになる。
- 配置（省略時 `--stack`）:
  - `--stack` 現在タブにスタックペインで追加（デフォルト）
  - `--tab`   `dev:<name>` という新規タブ（起動後フォーカスは呼び出し元タブに戻る）
  - `--float` フローティングペイン
  - `--split` 現在ペインを分割
- **cwd は今いるディレクトリが使われる。** 別ディレクトリなら `cd` してから呼ぶ。

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

- 出力は `/tmp/dev-servers/<name>.log` に tee される（ペイン表示は維持）。
- state は `/tmp/dev-servers/`（再起動で消える＝サーバーもどうせ止まるので整合）。
- 同名が既に alive なら `dev-up` は起動を拒否する。まず `dev-down <name>`。
- 停止は必ず記録済み ID 経由。裸の `close-tab` / `close-pane` は使わない
  （CLAUDE.md の zellij close-tab 事故ルール準拠）。
