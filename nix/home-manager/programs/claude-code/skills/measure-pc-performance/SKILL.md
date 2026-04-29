---
name: measure-pc-performance
version: 1.0.0
description: "Measure macOS PC performance — CPU thermal pressure (mTPL) residency, memory breakdown, swap usage, top memory consumers, and Jetsam events. Use when diagnosing thermal throttling or memory exhaustion. Works without sudo."
---

# measure-pc-performance

macOS（Apple Silicon推奨、Intel Mac可）のパフォーマンス状況を一括計測し、CPU交換・メモリ増設の判断材料となるレポートを生成する。

## 計測項目

1. **mTPL（measured Thermal Pressure Level）滞在時間** — CPUサーマル圧力
2. **物理メモリ内訳** — Free / Active / Inactive / Wired / Compressor
3. **スワップ使用量** — 物理メモリ不足の指標
4. **メモリ消費プロセス Top 15**
5. **Jetsamイベント累計** — メモリ不足による強制終了の履歴

## なぜこのSkillが必要か

`pmset -g therm` はTrapping（mTPL=3）以上の警告レベルしか記録しないため、Heavy（mTPL=2）レベルの熱圧力を見逃してしまう。本Skillは `thermalmonitord` のDebugログを直接解析することで、Heavyレベルの熱圧力も検出できる。

## 実行手順

以下のステップを順番に実行する。すべて **sudo不要**。

### Step 1: mTPL観測窓の起点を取得

unified logの保持期間 = `/var/db/diagnostics/Persist/` の最古tracev3ファイルの更新時刻。

```bash
OLDEST_TRACEV3=$(ls -lt /var/db/diagnostics/Persist/*.tracev3 | tail -1)
WINDOW_START=$(echo "$OLDEST_TRACEV3" | awk '{print $6, $7, $8}')
# 例: "Apr 13 15:33"
```

### Step 2: mTPLログを抽出

```bash
/usr/bin/log show \
  --start "$WINDOW_START" \
  --predicate 'process == "thermalmonitord" AND eventMessage CONTAINS "mTPL"' \
  --style compact \
  > /tmp/mtpl.log
```

### Step 3: mTPL集計（Python3ヒアドキュメント）

```bash
python3 << 'PYEOF'
import re
from datetime import datetime
import subprocess

# 観測窓の起点（tracev3最古時刻）を渡す
# Step 1 で取得したWINDOW_STARTをこのスクリプト内で再取得する方がロバスト
import os, glob
tracev3_files = glob.glob('/var/db/diagnostics/Persist/*.tracev3')
oldest = min(tracev3_files, key=os.path.getmtime)
window_start = datetime.fromtimestamp(os.path.getmtime(oldest))

events = []
with open('/tmp/mtpl.log') as f:
    for line in f:
        m = re.match(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+).*mTPL = (\d+)', line)
        if m:
            ts = datetime.strptime(m.group(1), '%Y-%m-%d %H:%M:%S.%f')
            events.append((ts, int(m.group(2))))

if not events:
    print("mTPLイベントが見つからない（システムが冷えていた可能性、または観測窓が短すぎる）")
    raise SystemExit(0)

# 観測窓先頭にmTPL=0を合成挿入（最初のイベントが mTPL=1 なら0→1遷移と推定）
if events[0][1] >= 1:
    events = [(window_start, 0)] + events

# 滞在時間を積算
residency = {}
for i in range(len(events) - 1):
    lvl = events[i][1]
    dt = (events[i+1][0] - events[i][0]).total_seconds()
    residency[lvl] = residency.get(lvl, 0) + dt

total = sum(residency.values())
level_names = {
    0: "Nominal（通常）",
    1: "Moderate（中程度）",
    2: "Heavy（重度）",
    3: "Trapping（深刻）",
    4: "Sleeping（強制スリープ）",
}

print(f"\n=== CPU サーマル圧力（mTPL）===")
print(f"観測期間: {total/3600:.2f} 時間 ({events[0][0]} → {events[-1][0]})")
print()
print(f"{'Level':<28} {'時間':>8}  {'割合':>7}  判定")
print("-" * 60)
for lvl in range(5):
    sec = residency.get(lvl, 0)
    pct = sec / total * 100 if total else 0
    name = level_names[lvl]
    if lvl >= 3 and sec > 0:
        mark = "🔴"
    elif lvl == 2 and pct > 10:
        mark = "⚠️"
    elif lvl == 2 and pct > 0:
        mark = "⚠️"
    else:
        mark = "✅"
    print(f"{name:<26} {sec/3600:>7.2f}h  {pct:>6.2f}%  {mark}")

from collections import Counter
counts = Counter(e[1] for e in events)
print(f"\n各レベルに入った回数: " + " / ".join(f"mTPL={k}: {v}回" for k, v in sorted(counts.items())))
PYEOF
```

### Step 4: 物理メモリ内訳

```bash
python3 << 'PYEOF'
import subprocess, re

out = subprocess.check_output(['vm_stat']).decode()
pagesize = 16384  # Apple Siliconは16KB、Intelは4KB
m = re.search(r'page size of (\d+) bytes', out)
if m:
    pagesize = int(m.group(1))

def parse(key):
    m = re.search(rf'{key}:\s+(\d+)', out)
    return int(m.group(1)) if m else 0

free = parse(r'Pages free')
active = parse(r'Pages active')
inactive = parse(r'Pages inactive')
wired = parse(r'Pages wired down')
comp_used = parse(r'Pages occupied by compressor')
comp_stored = parse(r'Pages stored in compressor')

total_bytes = int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']).strip())
total_gb = total_bytes / 1024**3

def to_gb(pages):
    return pages * pagesize / 1024**3

print(f"\n=== 物理メモリ内訳（物理 {total_gb:.1f} GB）===")
rows = [
    ("Free", to_gb(free), "🔴" if to_gb(free) < 0.5 else "✅"),
    ("Active", to_gb(active), ""),
    ("Inactive", to_gb(inactive), ""),
    ("Wired", to_gb(wired), ""),
    ("Compressor使用", to_gb(comp_used), ""),
]
print(f"{'領域':<18} {'サイズ':>8}  判定")
print("-" * 40)
for name, gb, mark in rows:
    print(f"{name:<16} {gb:>7.2f} GB  {mark}")
print(f"\nCompressor保持（元データ）: {to_gb(comp_stored):.2f} GB（圧縮保持）")
PYEOF
```

### Step 5: スワップ使用量

```bash
python3 << 'PYEOF'
import subprocess, re

out = subprocess.check_output(['sysctl', 'vm.swapusage']).decode()
m = re.search(r'total = ([\d.]+)M\s+used = ([\d.]+)M\s+free = ([\d.]+)M', out)
if m:
    total, used, free = map(float, m.groups())
    pct = used / total * 100 if total else 0
    mark = "🔴" if pct > 80 else "⚠️" if pct > 50 else "✅"
    print(f"\n=== スワップ使用量 ===")
    print(f"Total: {total/1024:.2f} GB / Used: {used/1024:.2f} GB ({pct:.1f}%) {mark}")
PYEOF
```

### Step 6: メモリ消費プロセス Top 15

```bash
echo ""
echo "=== メモリ消費プロセス Top 15 ==="
top -l 1 -n 15 -o mem -stats pid,command,mem 2>/dev/null | tail -16
```

### Step 7: Jetsamイベント累計

```bash
JETSAM_COUNT=$(/usr/bin/log show --predicate 'eventMessage CONTAINS "jetsam"' --style compact --last 30d 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "=== Jetsamイベント（過去30日）==="
if [ "$JETSAM_COUNT" = "0" ]; then
  echo "0件 ✅（メモリ不足によるプロセス強制終了なし）"
else
  echo "$JETSAM_COUNT 件 ⚠️（メモリ不足でプロセスが強制終了されている）"
fi
```

### Step 8: 総合評価

Claude Codeが上記の結果をまとめ、以下の観点で評価を出力する:

- **CPUサーマル**: Heavy滞在時間 > 10% → ⚠️ / Trapping以上 > 0 → 🔴
- **メモリ**: Free < 500MB → 🔴 / Swap使用率 > 80% → 🔴
- **Jetsam**: 累計 > 0 → ⚠️

評価結果に応じて、PC交換や設定変更の推奨事項を提案する。

## 出力イメージ

```
=== CPU サーマル圧力（mTPL）===
観測期間: 24.84 時間 (2026-04-13 15:33 → 2026-04-14 16:23)

Level                     時間       割合    判定
------------------------------------------------------------
Nominal（通常）         18.23h    73.36%  ✅
Moderate（中程度）       2.80h    11.28%  ⚠️
Heavy（重度）            3.82h    15.36%  ⚠️
Trapping（深刻）         0.00h     0.00%  ✅
Sleeping（強制スリープ） 0.00h     0.00%  ✅

各レベルに入った回数: mTPL=0: 15回 / mTPL=1: 296回 / mTPL=2: 286回

=== 物理メモリ内訳（物理 24.0 GB）===
領域                  サイズ   判定
----------------------------------------
Free                0.06 GB  🔴
Active              4.24 GB  
Inactive            3.85 GB  
Wired               4.76 GB  
Compressor使用     10.13 GB  

Compressor保持（元データ）: 56.96 GB（圧縮保持）

=== スワップ使用量 ===
Total: 22.00 GB / Used: 21.90 GB (99.7%) 🔴

=== メモリ消費プロセス Top 15 ===
[プロセス一覧]

=== Jetsamイベント（過去30日）===
0件 ✅

=== 総合評価 ===
- CPUサーマル: ⚠️ Heavy 15.36%（頻繁な熱圧力）
- メモリ: 🔴 Free 60MB、Swap 99.7%使用（深刻な逼迫）
- 推奨: PC交換（メモリ48GB以上）
```

## 注意事項

- **mTPL観測窓**: 通常24〜48時間（unified logの保持期間に依存）。長期計測が必要な場合はlaunchdエージェントで定期取得する別の仕組みが必要。
- **Apple SiliconとIntel**: `vm_stat` のページサイズはApple Siliconが16KB、Intel Macが4KB。スクリプトは自動判定する。
- **mTPLイベントが見つからない場合**: システムが冷えていた（熱圧力未発生）か、観測窓が極端に短いか、thermalmonitordがDebug出力を無効化されている。
- **全てsudo不要**: `log show`、`vm_stat`、`sysctl`、`top`、`ls /var/db/diagnostics/Persist/` すべて一般ユーザー権限で実行可能。

## Notionなどからコピーして使う場合

このSKILL.md全文を `~/.claude/skills/measure-pc-performance/SKILL.md` として保存すれば、Claude Codeから `/measure-pc-performance` または「PCパフォーマンスを計測して」と依頼して呼び出せる。
