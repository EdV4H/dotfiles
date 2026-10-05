#!/usr/bin/env bash
# Build a herdr workspace from scratch — the replacement for the old zellij KDL
# layouts (work.kdl / cockpit.kdl).
#
# usage: herdr-bootstrap <work|cockpit|grid [ROWS] [COLS] [--empty]>
#   grid [ROWS] [COLS]: 直近アクティブな ROWS×COLS 個(既定 2×4=8)のセッションを
#                       1タブのグリッド(ROWS行 × COLS列)に resume で並べる
#   grid ... --empty  : セッションを一切拾わず、空の ROWS×COLS グリッドだけ作る
#                       (ペインに何も入力しない / cwd は $HOME)。--no-resume も同義。
#
# Why a script and not a config file: herdr has no declarative layout format.
# A running herdr server keeps workspaces/tabs/panes itself and restores them
# after a restart, so day to day you never run this. It exists for the cases
# persistence can't cover: a new machine, or rebuilding a workspace you closed.
#
# Each project pane gets its command TYPED IN BUT NOT RUN (`pane send-text`
# sends no newline). That is the same ergonomics as the old layouts'
# `start_suspended true`: the tab is ready, you press Enter when you want it.
set -euo pipefail

layout="${1:-}"
case "$layout" in
  work|cockpit|grid) ;;
  *) echo "usage: $(basename "$0") <work|cockpit|grid [ROWS] [COLS] [--empty]>" >&2; exit 64 ;;
esac
shift || true

# grid のオプション。位置引数 (ROWS COLS) とフラグを混在で受ける。
EMPTY=0
GRID_ROWS=""
GRID_COLS=""
for a in "$@"; do
  case "$a" in
    --empty|--no-resume) EMPTY=1 ;;
    -*) echo "unknown option: $a" >&2; exit 64 ;;
    *)
      if [ -z "$GRID_ROWS" ]; then GRID_ROWS="$a"
      elif [ -z "$GRID_COLS" ]; then GRID_COLS="$a"
      fi
      ;;
  esac
done

preflight_bin="${HERDR_PREFLIGHT:-$HOME/.local/bin/herdr-preflight}"
[ -x "$preflight_bin" ] || preflight_bin=herdr-preflight
"$preflight_bin" herdr-bootstrap || exit $?

CLAUDE="claude"

WS_ID=""
SEED_TAB=""

# workspace <label> — create the workspace everything below goes into.
# herdr always gives a new workspace one empty tab; remember it and drop it at
# the end rather than trying to reuse it as the first project tab.
workspace() {
  local out
  out=$(herdr workspace create --label "$1" --cwd "$HOME" --no-focus)
  WS_ID=$(printf '%s' "$out" | jq -r '.result.workspace.workspace_id')
  SEED_TAB=$(printf '%s' "$out" | jq -r '.result.tab.tab_id')
  [ -n "$WS_ID" ] && [ "$WS_ID" != null ] || { echo "bootstrap: workspace create failed: $out" >&2; exit 70; }
}

# tab <label> <cwd-relative-to-HOME> [command...] → prints the new pane id
tab() {
  local label="$1" rel="$2"; shift 2
  local out pane
  out=$(herdr tab create --workspace "$WS_ID" --label "$label" --cwd "$HOME/$rel" --no-focus)
  pane=$(printf '%s' "$out" | jq -r '.result.root_pane.pane_id')
  if [ -z "$pane" ] || [ "$pane" = null ]; then
    echo "bootstrap: tab create failed for $label: $out" >&2
    exit 70
  fi
  if [ "$#" -gt 0 ]; then
    herdr pane send-text "$pane" "$*" >/dev/null
  fi
  printf '%s' "$pane"
}

# below <pane-id> <cwd-relative-to-HOME> [command...] → prints the new pane id
# herdr has no stacked panes, so the old `pane stacked=true` groups become
# ordinary splits below the project's main pane.
below() {
  local target="$1" rel="$2"; shift 2
  local out pane
  out=$(herdr pane split --pane "$target" --direction down --cwd "$HOME/$rel" --no-focus)
  pane=$(printf '%s' "$out" | jq -r '.result.pane.pane_id')
  if [ -z "$pane" ] || [ "$pane" = null ]; then
    echo "bootstrap: pane split failed under $target: $out" >&2
    exit 70
  fi
  if [ "$#" -gt 0 ]; then
    herdr pane send-text "$pane" "$*" >/dev/null
  fi
  printf '%s' "$pane"
}

# right <target-pane> <cwd-relative-to-HOME> [command...] → prints the new pane id.
# below の横方向版（split-right）。grid を組むのに使う。
right() {
  local target="$1" rel="$2"; shift 2
  local out pane
  out=$(herdr pane split --pane "$target" --direction right --cwd "$HOME/$rel" --no-focus)
  pane=$(printf '%s' "$out" | jq -r '.result.pane.pane_id')
  if [ -z "$pane" ] || [ "$pane" = null ]; then
    echo "bootstrap: pane split (right) failed under $target: $out" >&2
    exit 70
  fi
  if [ "$#" -gt 0 ]; then
    herdr pane send-text "$pane" "$*" >/dev/null
  fi
  printf '%s' "$pane"
}

build_work() {
  workspace Work
  local p

  p=$(tab Alchemy      "Projects/alchemy"                                  $CLAUDE -c)
  below "$p" "Projects/alchemy" nr dev >/dev/null

  tab English      "Projects/learn-english-app"                        $CLAUDE -c >/dev/null
  tab Widget       "Projects/wevox/wevox-mono-web/web-progressive"     $CLAUDE    >/dev/null
  tab Sort         "Projects/wevox"                                    $CLAUDE    >/dev/null
  tab Menu         "Projects/wevox/wevox-mono-web/web-progressive"     nvim       >/dev/null

  p=$(tab Croupier     "Projects/croupier"                                 $CLAUDE)
  below "$p" "Projects/croupier" nr dev >/dev/null

  tab Analytics    "Projects/wevox/wevox-mono-web/web-progressive"     $CLAUDE    >/dev/null
  tab dotfiles     "dotfiles"                                          $CLAUDE    >/dev/null

  p=$(tab DesignSystem "Projects/atrae-ui"                                 $CLAUDE)
  below "$p" "Projects/atrae-ui" >/dev/null

  tab Logo         "Projects/sandbox/wevox-logo-generator-handson"     $CLAUDE    >/dev/null
}

build_cockpit() {
  workspace Cockpit
  local p
  # Cockpit ran everything through claude's remote-control mode.
  local cc="$CLAUDE --remote-control -c"

  p=$(tab wevox "Projects/wevox" $cc)
  below "$p" "Projects/wevox" >/dev/null

  p=$(tab web-progressive "Projects/wevox/wevox-mono-web/web-progressive" $cc)
  below "$p" "Projects/wevox/wevox-mono-web/web-progressive" >/dev/null
  below "$p" "Projects/wevox/wevox" >/dev/null

  p=$(tab rest-bff "Projects/wevox/wevox-rest-bff" $cc)
  below "$p" "Projects/wevox/wevox-rest-bff" >/dev/null

  p=$(tab front "Projects/wevox/wevox-front" $cc)
  below "$p" "Projects/wevox/wevox-front" >/dev/null
  below "$p" "Projects/manifest" >/dev/null

  p=$(tab review "Projects" gh-review-watcher)
  below "$p" "Projects" >/dev/null

  p=$(tab scratch "Projects")
  below "$p" "Projects" >/dev/null

  p=$(tab dotfiles "dotfiles" $cc)
  below "$p" "dotfiles" >/dev/null
}

# grid [ROWS] [COLS]: 直近アクティブな ROWS×COLS 個(既定 2×4)のセッションを 1 タブ内の
# グリッド(ROWS行 × COLS列)に並べる。各ペインは cd 済み + `claude --resume <session-id>` を
# 入力済み(未実行, Enter で起動)。行優先で敷き詰める(セッションが足りなければ埋まる分だけ)。
#
# なぜ -c(continue) でなく resume <id> か: -c は「その dir の最新セッション」を継続するので、
# 同じディレクトリに複数セッションがあると取り違えるし、grid に同 dir が2枚あると両方が
# 同じセッションを掴んで競合する。セッションID を明示すれば取り違え・競合しない。

# grid ヘルパー（すべて HOME で split し、割当時に cd で移動する）。
# build_grid の local(SIDS/CWDS/total/cols) は bash の動的スコープで各ヘルパーから見える。
#
# 均等サイズの作り方: 「本数を半分ずつ」の再帰で木を組み、 各 split の比率をその枝が
# 受け持つ本数に比例させる。 以前は木だけ balanced にして split は常に 50/50 だったので、
# 本数が 2 の冪でないところで必ず崩れた ー 3 行なら 1/2, 1/4, 1/4、 5 行なら
# 1/4,1/4,1/4,1/8,1/8。 「3行目以降がどんどん小さくなる」のはこれ。 比率を half/k に
# すれば任意の行数・列数で完全に均等になる (3 → 1/3 で割ってから右を 50/50、 等)。
#
# --ratio が「元ペイン(左/上)の取り分」なのか「新ペイン(右/下)の取り分」なのかは、
# herdr の CLI ヘルプにも同梱 API スキーマ (PaneSplitParams.ratio) にも書かれていない。
# 推測せず、 使い捨ての split 1 回で実測して決める (grid_calibrate)。
RATIO_FIRST=1   # 1 = --ratio は「元ペイン(左/上)の取り分」

# 使い捨ての 0.25 split で --ratio の向きを判定し、 プローブは即閉じる。
# 判定できなければ既定 (RATIO_FIRST=1) のまま進む ー 最悪でも従来と同じ見た目になる。
grid_calibrate() {  # <pane>
  local out probe lay w0 w1
  out=$(herdr pane split --pane "$1" --direction right --ratio 0.25 --cwd "$HOME" --no-focus 2>/dev/null) || return 0
  probe=$(printf '%s' "$out" | jq -r '.result.pane.pane_id // empty' 2>/dev/null) || return 0
  [ -n "$probe" ] || return 0
  # 以降は必ずプローブを閉じてから抜ける。 `set -e` 下では代入の右辺が失敗すると
  # そこでスクリプトごと落ちるので、 herdr 側が pane layout を持たない世代でも
  # 死なないよう 1 つずつ握り潰す (判定できなければ既定のまま続行する)。
  lay=$(herdr pane layout --pane "$1" 2>/dev/null) || lay=""
  herdr pane close "$probe" >/dev/null 2>&1 || true
  [ -n "$lay" ] || return 0
  w0=$(printf '%s' "$lay" | jq -r --arg p "$1"     'first(.result.layout.panes[]? | select(.pane_id == $p) | .rect.width) // empty' 2>/dev/null) || return 0
  w1=$(printf '%s' "$lay" | jq -r --arg p "$probe" 'first(.result.layout.panes[]? | select(.pane_id == $p) | .rect.width) // empty' 2>/dev/null) || return 0
  case "${w0}:${w1}" in *[!0-9:]*|:*|*:) return 0 ;; esac
  if [ "$w0" -lt "$w1" ]; then RATIO_FIRST=1; else RATIO_FIRST=0; fi
}

# a/b を小数で (bash に浮動小数が無いので awk)
grid_frac() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.6f", a / b }'; }

grid_assign() {  # <pane> <session-index> : 名前 + `cd <cwd> && claude --resume <id>` を入力(未実行)
  # --empty ではペインを空のまま残す (rename も send-text もしない)。
  [ "$EMPTY" = "1" ] && return 0
  local pane="$1" cwd="${CWDS[$2]}" sid="${SIDS[$2]}"
  herdr pane rename "$pane" "$(basename "$cwd")" >/dev/null 2>&1 || true
  herdr pane send-text "$pane" "cd $(printf '%q' "$cwd") && $CLAUDE --resume $sid" >/dev/null
}

# <dir> <target-pane> <元ペインの取り分 0<r<1> → 新ペイン id
# (cwd は割当時に cd で合わせる)
grid_split1() {
  local dir="$1" target="$2" r="$3" out pane
  [ "$RATIO_FIRST" = 1 ] || r=$(awk -v x="$r" 'BEGIN { printf "%.6f", 1 - x }')
  out=$(herdr pane split --pane "$target" --direction "$dir" --ratio "$r" --cwd "$HOME" --no-focus)
  pane=$(printf '%s' "$out" | jq -r '.result.pane.pane_id')
  [ -n "$pane" ] && [ "$pane" != null ] || { echo "grid: split failed: $out" >&2; exit 70; }
  printf '%s' "$pane"
}

# <pane> を <dir> 方向に <k> 個の均等ペインへ分割し、セッション[ks..ks+k-1]を視覚順で割当。
grid_place() {  # <dir> <pane> <ks> <k>
  local dir="$1" pane="$2" ks="$3" k="$4"
  if [ "$k" -le 1 ]; then grid_assign "$pane" "$ks"; return; fi
  local half=$((k / 2)) rest np
  rest=$((k - half))
  # 前半が受け持つ本数 half に比例した取り分を与える (これが均等分割の肝)
  np=$(grid_split1 "$dir" "$pane" "$(grid_frac "$half" "$k")")   # pane=前半(左/上), np=後半(右/下)
  grid_place "$dir" "$pane" "$ks"            "$half"
  grid_place "$dir" "$np"   "$((ks + half))" "$rest"
}

# <pane> を下方向に <nr> 行へ均等分割し、各行(全幅)を列に割ってセッションを敷き詰める。
# 行を全部先に切ってから列に割るので各行が全幅になる。
grid_rows() {  # <pane> <row-start> <nr>
  local pane="$1" rs="$2" nr="$3"
  if [ "$nr" -le 1 ]; then
    local ch=$((total - rs * cols)); [ "$ch" -gt "$cols" ] && ch=$cols   # 最終行は余りだけ
    grid_place right "$pane" "$((rs * cols))" "$ch"
    return
  fi
  local half=$((nr / 2)) rest np
  rest=$((nr - half))
  # 行も同じ: 上側が受け持つ「行数」に比例させる。 50/50 で切ると 3 行以降が半分ずつ痩せる。
  np=$(grid_split1 down "$pane" "$(grid_frac "$half" "$nr")")
  grid_rows "$pane" "$rs"            "$half"
  grid_rows "$np"   "$((rs + half))" "$rest"
}

# 出来上がりを実測して 1 行で報告する。 均等化はサーバー側のセル丸めと最小ペイン幅に
# 左右されるので、 「指定どおりになったか」は見えるところに出しておく。
grid_report() {  # <any pane in the tab>
  local lay n wmin wmax hmin hmax
  lay=$(herdr pane layout --pane "$1" 2>/dev/null) || return 0
  read -r n wmin wmax hmin hmax <<<"$(printf '%s' "$lay" | jq -r '
      [.result.layout.panes[]?.rect] as $r
      | if ($r | length) == 0 then empty
        else "\($r|length) \($r|map(.width)|min) \($r|map(.width)|max) \($r|map(.height)|min) \($r|map(.height)|max)"
        end' 2>/dev/null)"
  [ -n "${n:-}" ] || return 0
  echo "grid: 実測 ${n}ペイン  幅 ${wmin}–${wmax}  高さ ${hmin}–${hmax} (±1 はセル丸め)"
}

build_grid() {
  local rows="${1:-2}" cols="${2:-4}"
  case "$rows" in ''|*[!0-9]*) rows=2 ;; esac
  case "$cols" in ''|*[!0-9]*) cols=4 ;; esac
  [ "$rows" -ge 1 ] 2>/dev/null || rows=2
  [ "$cols" -ge 1 ] 2>/dev/null || cols=4
  local n=$((cols * rows))
  local -a SIDS=() CWDS=()
  local total

  if [ "$EMPTY" = "1" ]; then
    # セッションを拾わず、要求された rows×cols をそのまま敷く。
    total=$n
  else
  # 直近アクティブな N セッションを .jsonl の mtime 順で拾う（このセッションは除外）。
  local SELF="7990c3e2-fa2b-4903-ae64-eeafdf18ef89"
  # NOTE: カウンタで数える。set -u の bash 3.2 では空配列の ${#arr[@]} が
  # "unbound variable" になるため、${#SIDS[@]} は使わない。
  local f sid cwd count=0
  while IFS= read -r f; do
    [ "$count" -ge "$n" ] && break
    sid=$(basename "$f" .jsonl)
    [ "$sid" = "$SELF" ] && continue
    # cwd はセッション transcript から (grep -m1 で先頭の "cwd":"..." を高速抽出)
    cwd=$(grep -m1 -oE '"cwd":"[^"]+"' "$f" 2>/dev/null | sed 's/^"cwd":"//; s/"$//')
    [ -n "$cwd" ] && [ -d "$cwd" ] || continue
    SIDS[$count]="$sid"; CWDS[$count]="$cwd"; count=$((count + 1))
  done < <(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null)

  total=$count
  [ "$total" -ge 1 ] || { echo "grid: 対象セッションが見つかりません (~/.claude/projects/*/*.jsonl)" >&2; exit 1; }
  fi

  workspace Grid
  # 実際に使う行数 = ceil(total/cols)（total は rows*cols で上限済みなので rows 以下）
  local arows=$(((total + cols - 1) / cols))
  [ "$arows" -gt "$rows" ] && arows=$rows

  # グリッドの最初のペイン（タブの root）を HOME で作る
  local out first
  out=$(herdr tab create --workspace "$WS_ID" --label grid --cwd "$HOME" --no-focus)
  first=$(printf '%s' "$out" | jq -r '.result.root_pane.pane_id')
  [ -n "$first" ] && [ "$first" != null ] || { echo "grid: tab create failed: $out" >&2; exit 70; }

  [ $((arows * cols)) -gt 1 ] && grid_calibrate "$first"
  grid_rows "$first" 0 "$arows"    # 均等に行→列へ分割してセッションを敷き詰める
  grid_report "$first"
  if [ "$EMPTY" = "1" ]; then
    echo "grid: 空の ${rows}行×${cols}列(均等)グリッドを作成（コマンドは入れていない / cwd=\$HOME）"
  else
    echo "grid: $total セッションを ${rows}行×${cols}列(均等)グリッドに配置（各ペインで Enter → resume）"
  fi
}

case "$layout" in
  work)    build_work ;;
  cockpit) build_cockpit ;;
  grid)    build_grid "$GRID_ROWS" "$GRID_COLS" ;;
esac

# Drop the empty tab herdr created with the workspace.
[ -n "$SEED_TAB" ] && [ "$SEED_TAB" != null ] && herdr tab close "$SEED_TAB" >/dev/null 2>&1 || true

echo "herdr-bootstrap: built '$layout' in workspace $WS_ID"
if [ "$EMPTY" = "1" ]; then
  echo "  ペインは空。 コマンドは入れていない。"
else
  echo "  各タブのコマンドは入力済みで未実行。 Enter で起動する。"
fi
