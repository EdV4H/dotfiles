#!/usr/bin/env bash
# Build a herdr workspace from scratch — the replacement for the old zellij KDL
# layouts (work.kdl / cockpit.kdl).
#
# usage: herdr-bootstrap <work|cockpit>
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
  work|cockpit) ;;
  *) echo "usage: $(basename "$0") <work|cockpit>" >&2; exit 64 ;;
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

case "$layout" in
  work)    build_work ;;
  cockpit) build_cockpit ;;
esac

# Drop the empty tab herdr created with the workspace.
[ -n "$SEED_TAB" ] && [ "$SEED_TAB" != null ] && herdr tab close "$SEED_TAB" >/dev/null 2>&1 || true

echo "herdr-bootstrap: built '$layout' in workspace $WS_ID"
echo "  各タブのコマンドは入力済みで未実行。 Enter で起動する。"
