#!/usr/bin/env bash
# Stop a dev server started by `dev-up`: kill its process group, then remove
# the zellij pane/tab it lives in.
#
# Safety: it only ever closes a surface it can identify BY ID —
#   - tab mode:  close-tab-by-id <tabid>
#   - pane mode: focus-pane-id <id> + close-pane, and ONLY when an exact live
#     pane named dev:<name> is found in `list-panes`.
# It never runs a bare `close-tab` / `close-pane` against the focused surface
# (see CLAUDE.md's zellij close-tab warning — silent fails destroy the wrong tab).
#
# usage: dev-down <name>
set -uo pipefail

statedir="${DEV_SERVERS_DIR:-/tmp/claude/dev-servers}"  # stable, sandbox-writable (see dev-up)
name="${1:-}"
[ -z "$name" ] && { echo "usage: dev-down <name>" >&2; exit 64; }

meta="$statedir/$name.meta"
pidfile="$statedir/$name.pid"

metaval() { grep -m1 "^$1=" "$2" 2>/dev/null | cut -d= -f2-; }
kind=""; tabid=""
if [ -f "$meta" ]; then
  kind=$(metaval kind "$meta")
  tabid=$(metaval tabid "$meta")
fi

# 1) kill the whole process tree via the recorded process-group id.
if [ -f "$pidfile" ]; then
  pgid="$(cat "$pidfile" 2>/dev/null)"
  if [ -n "$pgid" ]; then
    kill -TERM "-$pgid" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      kill -0 "$pgid" 2>/dev/null || break
      sleep 0.3
    done
    kill -KILL "-$pgid" 2>/dev/null || true
  fi
fi

# 2) remove the zellij surface.
case "$kind" in
  tab)
    [ -n "$tabid" ] && zellij action close-tab-by-id "$tabid" 2>/dev/null || true
    ;;
  stack|float|split)
    # The pane had --close-on-exit, so killing its command normally closed it.
    # Fallback: close only an EXACT live match, focused by its own id.
    pid_live="$(zellij action list-panes 2>/dev/null | awk -v n="dev:$name" '$3==n{print $1; exit}')"
    if [ -n "$pid_live" ]; then
      zellij action focus-pane-id "$pid_live" 2>/dev/null || true
      zellij action close-pane 2>/dev/null || true
    fi
    ;;
esac

rm -f "$meta" "$pidfile"
echo "dev:$name stopped"
