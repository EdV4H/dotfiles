# herdr の通知音

herdr (0.8.2 時点) には **音量パラメータが無い**。 `[ui.sound]` にあるのは
`enabled` / `path` / `done_path` / `request_path` / `[ui.sound.agents]` (エージェント別 on/off) だけ。
既定音はバイナリ埋め込みで mp3 として取り出せないため、 **音量調整 = 自前の静かな mp3 に差し替え**
という形で実現している。

現在の中身 (macOS システム音を -12dB = `volume=0.25` に落としたもの):

| ファイル | 元 | 用途 |
| --- | --- | --- |
| `done.mp3` | `/System/Library/Sounds/Tink.aiff` | 作業完了通知 |
| `request.mp3` | `/System/Library/Sounds/Ping.aiff` | 要対応 (needs attention) 通知 |

## 音量を変える

`volume=` を上げ下げして作り直す (0.25 → もっと静かにするなら 0.15 等):

```bash
cd nix/home-manager/programs/herdr/sounds
ffmpeg -y -i /System/Library/Sounds/Tink.aiff -af "volume=0.25" \
  -codec:a libmp3lame -q:a 5 -ac 2 -ar 44100 done.mp3
ffmpeg -y -i /System/Library/Sounds/Ping.aiff -af "volume=0.25" \
  -codec:a libmp3lame -q:a 5 -ac 2 -ar 44100 request.mp3
```

反映は `nix run .#update` → `herdr server reload-config` (または prefix+shift+r)。

## 音そのものを変える

`/System/Library/Sounds/` の任意の aiff を元に同じコマンドを回せばよい
(Basso / Blow / Bottle / Frog / Funk / Glass / Hero / Morse / Ping / Pop / Purr / Sosumi / Submarine / Tink)。

## 完全に消したい場合

`config.toml` の `[ui.sound]` に `enabled = false` を足す。
特定エージェントだけ黙らせたいなら `[ui.sound.agents]` で `<agent> = "off"`。
