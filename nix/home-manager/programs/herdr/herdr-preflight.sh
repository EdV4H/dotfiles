#!/usr/bin/env bash
# Can this CLI reach the herdr server? Exit 0 if yes. Otherwise explain WHY on
# stderr and exit 69 (EX_UNAVAILABLE).
#
# usage: herdr-preflight [caller-name]
#   caller-name only prefixes the messages (defaults to "herdr-preflight").
#
# Why this exists: "herdr tab list fails" has two completely different causes and
# the CLI does not distinguish them.
#
#   1. No server at all      → the socket file is missing.
#   2. A server IS running,   → the socket is there and something is listening,
#      but this CLI is a        but the versions don't match.
#      different version.
#
# Case 2 bit hard. 2026-09-11: `nix run .#update` moved the CLI to herdr 0.9.0
# while the 0.8.x server started on 2026-09-07 kept running. 0.9.0 refuses
# servers "older than endpoint generation 1", so every CLI call began failing —
# dev-up, but also gh-review-watcher's open-review-tab / close-merged-review-tab
# under launchd — for three days, silently, while the herdr UI itself worked
# perfectly. The only visible symptom was dev-up saying "can't reach a herdr
# server. Start one with `herdr` first", which is exactly the wrong advice: a
# server WAS running, and starting another one is impossible.
#
# Proof it was version skew, for the next time: the server log records every
# UI-changing API call, and `cli:tab:create` / `cli:tab:close` (912 + 804 of
# them) stop dead at 2026-09-10T15:17, the last moment before the 0.9.0 client
# landed. Read-only calls like tab.list are not logged, so absence of those
# proves nothing — look at the write calls.
#
# Callers: dev-up, dev-supervise, herdr-bootstrap, open-review-tab,
# close-merged-review-tab, close-conflict-tab.
set -uo pipefail

SELF="${1:-herdr-preflight}"
say() { echo "$SELF: $*" >&2; }
note() { echo "  $*" >&2; }

herdr tab list >/dev/null 2>&1 && exit 0

# herdr's socket path is fixed (not $TMPDIR-derived like zellij's), so a
# sandboxed shell and your real one look at the same file. $HERDR_SOCKET_PATH is
# set inside every pane and wins when present.
sock="${HERDR_SOCKET_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/herdr.sock}"

if [ ! -S "$sock" ]; then
  say "no herdr server — no socket at $sock."
  note "Start one with \`herdr\` first."
  exit 69
fi

client=$(herdr --version 2>/dev/null | awk 'NF{print $NF}')
server=$(herdr status --json 2>/dev/null |
  jq -r '.server.version? // (.. | objects | select(has("version")) | .version) // empty' 2>/dev/null |
  head -1)

skew=1
say "a herdr server is listening on $sock, but this CLI cannot talk to it."
if [ -n "$server" ] && [ -n "$client" ] && [ "$server" != "$client" ]; then
  note "Version mismatch: server $server, client $client."
elif [ -n "$server" ] && [ "$server" = "$client" ]; then
  skew=0
  note "Both sides report $server, so this is not a version skew — the socket is"
  note "probably stale (a server died without removing it)."
elif [ -n "$client" ]; then
  note "Could not read the server version (client is $client) — the server is"
  note "most likely older than the installed binary."
fi

if [ "$skew" = 1 ]; then
  note "This is what an upgrade-without-restart looks like: \`nix run .#update\`"
  note "replaced the binary, but the already-running server kept the old one."
  note "Restart it so it adopts the new binary:"
else
  note "Restart it either way:"
fi
note "  herdr status          # confirm the two versions"
note "  herdr server stop     # if that fails: pkill -f 'herdr server'"
note "  herdr                 # start again"
note "This kills every pane's processes; 'herdr-bootstrap grid' brings the"
note "claude sessions back."
[ "$skew" = 1 ] && note "Do NOT run \`herdr update\` — the binary is nix-managed; upgrade with \`nix run .#update\`."

exit 69
