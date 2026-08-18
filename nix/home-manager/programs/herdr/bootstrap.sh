#!/usr/bin/env bash
# Build a herdr workspace from scratch — the replacement for the old zellij KDL
# layouts (work.kdl / cockpit.kdl).
#
# usage: herdr-bootstrap <work|cockpit|grid>
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
  *) echo "usage: $(basename "$0") <work|cockpit|grid>" >&2; exit 64 ;;
esac

if ! herdr tab list >/dev/null 2>&1; then
  echo "herdr-bootstrap: no reachable herdr server. Start one with \`herdr\` first." >&2
  exit 69
fi

CLAUDE="claude --dangerously-skip-permissions"

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

# grid: 1 タブに「よく見る8個」を 4列×2行の均等グリッドで並べる（cockpit を一望する用）。
# 各ペインは cd 済み・コマンド入力済みで未実行（Enter で起動する）。
# ★「よく見る8個」はこの LIST を編集する: "ラベル|HOME からの相対パス"、上段4→下段4 の順。
build_grid() {
  workspace Grid
  local cc="$CLAUDE -c"    # 各ペインでそのディレクトリの最新セッションを継続

  # --- 上段(左→右) 4 個 ---
  local A1="web-prog|Projects/wevox/wevox-mono-web/web-progressive"
  local A2="wevox|Projects/wevox"
  local A3="rest-bff|Projects/wevox/wevox-rest-bff"
  local A4="front|Projects/wevox/wevox-front"
  # --- 下段(左→右) 4 個 ---
  local B1="atrae-ui|Projects/atrae-ui"
  local B2="usketch|Projects/usketch"
  local B3="russell|Projects/russell"
  local B4="dotfiles|dotfiles"

  local a bot a_2 a_3 a_4 b_2 b_3 b_4
  # まず 2 行に分割（a=上段の最初のペイン, bot=下段）
  a=$(  tab   "${A1%%|*}" "${A1#*|}" $cc)
  bot=$(below "$a"        "${B1#*|}" $cc); herdr pane rename "$bot" "${B1%%|*}" >/dev/null 2>&1 || true

  # 上段を均等4列に（バランス分割 → 見た目 左→右 = A1 A2 A3 A4）
  a_3=$(right "$a"   "${A3#*|}" $cc); herdr pane rename "$a_3" "${A3%%|*}" >/dev/null 2>&1 || true
  a_2=$(right "$a"   "${A2#*|}" $cc); herdr pane rename "$a_2" "${A2%%|*}" >/dev/null 2>&1 || true
  a_4=$(right "$a_3" "${A4#*|}" $cc); herdr pane rename "$a_4" "${A4%%|*}" >/dev/null 2>&1 || true

  # 下段を均等4列に（左→右 = B1 B2 B3 B4）
  b_3=$(right "$bot" "${B3#*|}" $cc); herdr pane rename "$b_3" "${B3%%|*}" >/dev/null 2>&1 || true
  b_2=$(right "$bot" "${B2#*|}" $cc); herdr pane rename "$b_2" "${B2%%|*}" >/dev/null 2>&1 || true
  b_4=$(right "$b_3" "${B4#*|}" $cc); herdr pane rename "$b_4" "${B4%%|*}" >/dev/null 2>&1 || true
}

case "$layout" in
  work)    build_work ;;
  cockpit) build_cockpit ;;
  grid)    build_grid ;;
esac

# Drop the empty tab herdr created with the workspace.
[ -n "$SEED_TAB" ] && [ "$SEED_TAB" != null ] && herdr tab close "$SEED_TAB" >/dev/null 2>&1 || true

echo "herdr-bootstrap: built '$layout' in workspace $WS_ID"
echo "  各タブのコマンドは入力済みで未実行。 Enter で起動する。"
