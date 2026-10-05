#!/usr/bin/env bash
set -euo pipefail

# gh-review-watcher on_remove hook: リストから消えたPRのレビュータブを閉じる
# Arguments: {number} {repo}
#
# herdr のタブはコマンド終了で自動的には消えない (zellij の --close-on-exit 相当が
# 無い) ため、 このフックが review タブの唯一の後片付け経路になる。
NUMBER="$1"
REPO="$2"

HOOK_LOG="${GH_REVIEW_WATCHER_LOG:-/tmp/gh-review-watcher-hooks.log}"

# herdr に届かないときに素通りさせない。 herdr-tab-id は「サーバーに届かない」と
# 「そんなタブは無い」をどちらも空文字で返すので、 preflight しないとこのスクリプトは
# exit 0 (= 片付け済み) を装ってしまう。 タブは閉じられないまま溜まり続ける。
preflight_bin="${HERDR_PREFLIGHT:-$HOME/.local/bin/herdr-preflight}"
[ -x "$preflight_bin" ] || preflight_bin=herdr-preflight
if ! PF_ERR=$("$preflight_bin" close-merged-review-tab 2>&1); then
  printf '%s\n' "$PF_ERR" | tee -a "$HOOK_LOG" >&2
  exit 69
fi

TAB_NAME="Review: ${REPO}#${NUMBER}"

# レビュータブが存在しなければ何もしない
TAB_ID=$(herdr-tab-id "$TAB_NAME" || true)

if [[ -z "$TAB_ID" ]]; then
  exit 0
fi

herdr tab close "$TAB_ID"
echo "[CLOSED TAB] ${TAB_NAME}" >> /tmp/gh-review-watcher-hooks.log
