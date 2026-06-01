#!/usr/bin/env bash
set -euo pipefail

# pr-conflict-check が開いた "Conflict: <repo>#<num>" タブを安全に閉じる。
# usage: close-conflict-tab <repo> <num>
# 例: close-conflict-tab Atrae/wevox-mono-web 9664
#
# zellij action close-tab はフォーカスのタブを閉じてしまうため、必ず
# list-tabs --json から該当タブの ID を引いて close-tab-by-id で閉じる。
# 該当タブが存在しなければ何もせず exit 0。

REPO="${1:-}"
NUM="${2:-}"

if [ -z "$REPO" ] || [ -z "$NUM" ]; then
  echo "usage: $(basename "$0") <repo> <num>" >&2
  exit 2
fi

TAB_NAME="Conflict: ${REPO}#${NUM}"

TAB_ID=$(zellij action list-tabs --json 2>/dev/null \
  | jq -r --arg name "$TAB_NAME" '.[] | select(.name == $name) | .tab_id' 2>/dev/null \
  || true)

if [ -z "$TAB_ID" ]; then
  echo "tab not found: $TAB_NAME"
  exit 0
fi

zellij action close-tab-by-id "$TAB_ID"
echo "closed: $TAB_NAME (id=$TAB_ID)"
