#!/usr/bin/env bash
# Start a long-running dev server inside a zellij pane/tab so it SURVIVES.
#
# Why: a `!`-backgrounded or `run_in_background` process is a child of the
# Claude Code harness and gets reaped with SIGTERM (exit 143) after a while.
# A pane/tab command is a child of the zellij server instead, outside the
# harness's process tree, so it keeps running until you `dev-down` it.
#
# usage: dev-up [--keep] [--stack|--tab|--float|--split] <name> [--] <cmd> [args...]
#   --stack  (default) stacked pane in the current tab
#   --tab    a new tab named  dev:<name>  (focus returns to the caller's tab)
#   --float  a floating pane
#   --split  split the current pane
#   --keep   mark this server "supervised" so `dev-supervise` auto-restarts it if
#            it dies. Real dev servers (pnpm/vite) get SIGTERM'd after a while by
#            something that targets servers specifically; --keep makes them self-heal.
#
# examples:
#   dev-up weboard -- pnpm dev:proxy --filter weboard
#   dev-up --keep --tab api -- pnpm --filter api dev
set -euo pipefail

# /tmp/claude is a STABLE, sandbox-writable path shared across every context that
# touches this state — Claude Code's Bash sandbox, your real shell, and the zellij
# pane (dev-serve-run). $TMPDIR is NOT usable: it differs per context, so dev-up
# and dev-down would compute different dirs and never see each other's state.
statedir="${DEV_SERVERS_DIR:-/tmp/claude/dev-servers}"
runner_bin="${DEV_SERVE_RUN:-$HOME/.local/bin/dev-serve-run}"
place=stack
keep=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --stack) place=stack; shift ;;
    --tab)   place=tab;   shift ;;
    --float) place=float; shift ;;
    --split) place=split; shift ;;
    --keep)  keep=1;      shift ;;
    --) shift; break ;;
    --*) echo "dev-up: unknown flag $1" >&2; exit 64 ;;
    *) break ;;
  esac
done

name="${1:-}"
[ -z "$name" ] && { echo "usage: dev-up [--stack|--tab|--float|--split] <name> -- <cmd...>" >&2; exit 64; }
shift
[ "${1:-}" = "--" ] && shift
[ "$#" -eq 0 ] && { echo "dev-up: no command given" >&2; exit 64; }

case "$name" in
  *[!A-Za-z0-9._-]*) echo "dev-up: name may only contain [A-Za-z0-9._-]" >&2; exit 64 ;;
esac

[ -z "${ZELLIJ:-}" ] && { echo "dev-up: must run inside a zellij session" >&2; exit 69; }

# Preflight: confirm we can actually reach the zellij control socket. A sandboxed
# shell (Claude Code's Bash) has its own $TMPDIR, so it looks for the socket in the
# wrong place and can't connect — turning an otherwise cryptic "no active session"
# into clear guidance. Monitoring/stop still work from the sandbox via shared state.
if ! zellij action query-tab-names >/dev/null 2>&1; then
  {
    echo "dev-up: can't reach the zellij session from this shell."
    echo "  zellij's socket/logs live under the server's \$TMPDIR; a sandboxed shell"
    echo "  (e.g. Claude Code's Bash, \$TMPDIR=$TMPDIR) has a different one and can't"
    echo "  connect. Run dev-up in your REAL shell / zellij pane, or export the zellij"
    echo "  server's \$TMPDIR first."
    echo "  Note: dev-logs / dev-list / dev-down still work here — they share state at"
    echo "  $statedir, so a server you start in your real shell is visible from Claude."
  } >&2
  exit 69
fi

[ -x "$runner_bin" ] && : || runner_bin="dev-serve-run"  # fall back to PATH lookup

mkdir -p "$statedir"
meta="$statedir/$name.meta"
log="$statedir/$name.log"
pidfile="$statedir/$name.pid"

if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
  echo "dev-up: dev:$name already running (pgid=$(cat "$pidfile")). Run 'dev-down $name' first." >&2
  exit 1
fi

# Restart hygiene: if a previous same-named server died and left its surface
# behind, close that surface BY ID first (never a bare close-tab/close-pane) so a
# restart — e.g. by dev-supervise — doesn't pile up dead tabs/panes.
if [ -f "$meta" ]; then
  old_kind=$(grep -m1 '^kind=' "$meta" 2>/dev/null | cut -d= -f2-)
  old_tabid=$(grep -m1 '^tabid=' "$meta" 2>/dev/null | cut -d= -f2-)
  if [ "$old_kind" = tab ] && [ -n "$old_tabid" ]; then
    zellij action close-tab-by-id "$old_tabid" 2>/dev/null || true
  elif [ "$old_kind" != tab ]; then
    # pane modes ran with --close-on-exit, so a dead pane is normally already gone.
    # Only if an EXACT live pane named dev:<name> lingers, focus it by id and close.
    pid_live=$(zellij action list-panes 2>/dev/null | awk -v n="dev:$name" '$3==n{print $1; exit}')
    if [ -n "$pid_live" ]; then
      zellij action focus-pane-id "$pid_live" 2>/dev/null || true
      zellij action close-pane 2>/dev/null || true
    fi
  fi
fi

cwd="$PWD"
: > "$log"

# Record argv (NUL-delimited) so dev-supervise can respawn with the exact command.
printf '%s\0' "$@" > "$statedir/$name.argv"

case "$place" in
  tab)
    tabid=$(zellij action new-tab --name "dev:$name" -- \
      "$runner_bin" "$name" "$log" "$pidfile" "$cwd" "$PATH" -- "$@" | tr -dc '0-9')
    zellij action go-to-previous-tab 2>/dev/null || true
    {
      echo "kind=tab"
      echo "tabid=$tabid"
      echo "cwd=$cwd"
      echo "keep=$keep"
      printf 'cmd=%s\n' "$*"
    } > "$meta"
    ;;
  *)
    opt=()
    case "$place" in
      float) opt=(--floating) ;;
      split) opt=() ;;
      stack) opt=(--stacked) ;;
    esac
    paneid=$(zellij action new-pane "${opt[@]}" --close-on-exit --name "dev:$name" -- \
      "$runner_bin" "$name" "$log" "$pidfile" "$cwd" "$PATH" -- "$@")
    {
      echo "kind=$place"
      echo "paneid=$paneid"
      echo "cwd=$cwd"
      echo "keep=$keep"
      printf 'cmd=%s\n' "$*"
    } > "$meta"
    ;;
esac

echo "dev:$name up ($place$([ "$keep" = 1 ] && echo ', supervised'))  log: $log"
echo "  dev-logs $name    # tail output (use this to check it started / see errors)"
echo "  dev-down $name    # stop it$([ "$keep" = 1 ] && echo ' (and stop supervising)')"
[ "$keep" = 1 ] && echo "  (run 'dev-supervise' once — in a tab — so a watchdog restarts it if it dies)"
true
