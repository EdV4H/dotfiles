#!/usr/bin/env bash
# Internal wrapper launched *inside* a zellij pane/tab by `dev-up`.
#
# Why it exists:
#  - It records this shell's PID as the process-group leader so `dev-down` can
#    stop the whole tree (pnpm -> node -> vite ...) with `kill -TERM -<pgid>`.
#    Job control is off in scripts, so every child stays in this pgid == $$.
#  - It tees output to a logfile so `dev-logs` (and Claude, headless) can read
#    the server's output without stealing the zellij pane.
#
# argv: <name> <logfile> <pidfile> <cwd> -- <cmd> [args...]
#
# The logfile and pidfile paths are passed explicitly (not derived from env)
# because this runs *inside a zellij pane* and does NOT inherit the caller's
# environment — it inherits the zellij server's. So dev-up hands us exactly
# where to write.
set -u

name="${1:?dev-serve-run: missing name}"
log="${2:?dev-serve-run: missing logfile}"
pidfile="${3:?dev-serve-run: missing pidfile}"
cwd="${4:?dev-serve-run: missing cwd}"
shift 4
[ "${1:-}" = "--" ] && shift
if [ "$#" -eq 0 ]; then
  echo "dev-serve-run: no command given" >&2
  exit 64
fi

mkdir -p "$(dirname "$pidfile")"

# $$ is this non-interactive shell's PID and, with job control off, the process
# group leader for every child it spawns. Record it for `dev-down`.
echo "$$" > "$pidfile"

cd "$cwd" || { echo "dev-serve-run: cannot cd to $cwd" | tee -a "$log" >&2; exit 66; }

{
  echo "▶ dev:$name started $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  cwd : $cwd"
  echo "  cmd : $*"
  echo "  pgid: $$"
  echo "  ---"
} | tee -a "$log"

# Mirror all further output to the logfile while keeping it visible in the pane.
exec > >(tee -a "$log") 2>&1

"$@"
status=$?
echo "■ dev:$name exited (status=$status) $(date '+%Y-%m-%d %H:%M:%S')"
exit "$status"
