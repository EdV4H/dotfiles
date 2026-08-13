#!/usr/bin/env bash
set -euo pipefail

# gh-review-watcher から呼ばれる: "Review: <repo>#<num>" タブを開いて review-pr を走らせる。
# usage: open-review-tab <url> <number> <repo>
#
# 旧 zellij 版は `new-tab --close-on-exit -- review-pr ...` の 1 行だったが、 herdr には
#   - コマンドを直接生やす new-tab 相当が無い (tab create → pane run で打ち込む)
#   - --close-on-exit が無い (タブはコマンド終了後も残る。 後片付けは
#     close-merged-review-tab が on_remove で行う)
# ため、 スクリプトに切り出してある。 同名タブが既にあれば focus するだけ。

URL="${1:-}"
NUMBER="${2:-}"
REPO="${3:-}"

if [ -z "$URL" ] || [ -z "$NUMBER" ] || [ -z "$REPO" ]; then
  echo "usage: $(basename "$0") <url> <number> <repo>" >&2
  exit 2
fi

TAB_NAME="Review: ${REPO}#${NUMBER}"

EXISTING=$(herdr-tab-id "$TAB_NAME" || true)
if [ -n "$EXISTING" ]; then
  herdr tab focus "$EXISTING" >/dev/null
  echo "focused existing tab: $TAB_NAME"
  exit 0
fi

# --no-focus: レビュー依頼が飛んできても作業中のタブを奪わない
# (旧構成の new-tab + go-to-previous-tab の置き換え)。
CREATED=$(herdr tab create --label "$TAB_NAME" --no-focus)
PANE_ID=$(printf '%s' "$CREATED" | jq -r '.result.root_pane.pane_id // empty')

if [ -z "$PANE_ID" ]; then
  echo "open-review-tab: no pane id in herdr response: $CREATED" >&2
  exit 70
fi

herdr pane run "$PANE_ID" "$(printf '%q ' review-pr "$URL" "$NUMBER" "$REPO")" >/dev/null
echo "opened: $TAB_NAME (pane=$PANE_ID)"
