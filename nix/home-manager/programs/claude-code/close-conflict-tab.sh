#!/usr/bin/env bash
set -euo pipefail

# pr-conflict-check が開いた "Conflict: <repo>#<num>" タブを閉じる。
# usage: close-conflict-tab <repo> <num>
# 例: close-conflict-tab Atrae/wevox-mono-web 9664
#
# herdr の `tab close` は tab_id 必須なので、 旧 zellij の「裸の close-tab が
# フォーカス中のタブを巻き込む」事故は構造的に起きない。 label から id を引いて
# 閉じるだけ。 該当タブが無ければ何もせず exit 0。

REPO="${1:-}"
NUM="${2:-}"

if [ -z "$REPO" ] || [ -z "$NUM" ]; then
  echo "usage: $(basename "$0") <repo> <num>" >&2
  exit 2
fi

# herdr-tab-id は「届かない」も「無い」も空で返すので、 preflight しないと
# サーバー断絶時に "tab not found" と言って exit 0 してしまう。
preflight_bin="${HERDR_PREFLIGHT:-$HOME/.local/bin/herdr-preflight}"
[ -x "$preflight_bin" ] || preflight_bin=herdr-preflight
"$preflight_bin" close-conflict-tab || exit $?

TAB_NAME="Conflict: ${REPO}#${NUM}"

TAB_ID=$(herdr-tab-id "$TAB_NAME" || true)

if [ -z "$TAB_ID" ]; then
  echo "tab not found: $TAB_NAME"
  exit 0
fi

herdr tab close "$TAB_ID"
echo "closed: $TAB_NAME (id=$TAB_ID)"
