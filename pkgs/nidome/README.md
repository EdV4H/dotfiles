# nidome

ターミナルで失敗したコマンドとその出力を記録し、 同じエラーで二度悩まないための CLI。
計画: [ターミナルエラー記録ツール 実装計画](https://claude.ai/code/artifact/91282696-63e2-4294-9c11-93cdd50b7a41)

現在は **M0 (検証用の試作)**。 失敗したコマンドの出力末尾を JSONL に書くところまで。

## 試す

```sh
go build -o bin/nidome ./cmd/nidome

# ~/.zshrc
eval "$(nidome init zsh)"

# 出力も記録するにはシェルをラッパー経由で起動する
nidome shell        # $SHELL を PTY の子として起動
nidome log          # 記録 (~/.local/share/nidome/m0.jsonl)
```

## 仕組み

- `nidome init zsh` のフックが各コマンドの前後に OSC 133 マーカー (`C` = 出力開始、 `D;<exit>` = 終了) を出す。
  ラッパー配下 (`NIDOME_PTY=1`) ではコマンド文字列と cwd を独自 OSC `7771;nidome;…` でも送る。
- `nidome shell` は出力をそのまま端末に流しつつ、 マーカー間の出力を ANSI を除いて行単位で保持し
  (末尾 200 行)、 終了コード ≠ 0 なら記録する。 独自 OSC は端末に届く前に取り除く。
- 代替画面 (`?1049h` 等。 vim / less / htop) の間の出力は記録しない。 CR で上書きされる進捗表示は最後の状態だけ残す。

## M0 の検証結果 (2026-10-12、 Linux コンテナ / zsh 5.9)

| 項目 | 結果 |
| --- | --- |
| 失敗コマンドの出力取得 | stdout / stderr とも取得。 `ls`、 `sh -c '…; exit 3'`、 `less <無いファイル>` で確認 |
| vim | 編集・保存が正常。 実行中のリサイズが vim に届く (100x30 を確認) |
| less / htop | 表示・終了とも正常。 代替画面中の出力は記録されない |
| リサイズ | SIGWINCH で内側の pty に反映 (`stty size` で確認) |
| 終了コード | `exit 7` がラッパーの終了コードに伝わる |
| フックの負荷 | preexec + precmd で約 50µs / コマンド (fork なし) |
| ラッパーの遅延 | キー入力のエコー p50: 直接 0.08ms → 経由 0.18ms。 コマンド往復 p50: 0.29ms → 0.43ms |
| スループット | `seq 1 2000000` (約 15MB): 直接 0.94s → 経由 1.00s |

計画の非機能要件 (遅延 20ms 以内) は十分に満たす。 未確認なのは macOS 実機、 WezTerm / zellij 配下での動作。

## 次 (M1)

SQLite 保存、 秘密情報マスク、 フィンガープリント v1、 `list` / `show` / `search` / `note` / `resolve`、 再発時の表示。
