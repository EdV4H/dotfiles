#!/usr/bin/env bash
set -euo pipefail

export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export HOME=/Users/yusukemaruyama

LOG_FILE="/tmp/pr-conflict-check.log"
DRY_RUN="${PR_CONFLICT_DRY_RUN:-0}"
TARGET_PR="${1:-}"

log() {
  echo "$(date '+%Y-%m-%dT%H:%M:%S') $*" >> "$LOG_FILE"
}

log "=== Starting pr-conflict-check (dry_run=$DRY_RUN, target=${TARGET_PR:-<all>}) ==="

# 古い shallow clone を掃除 (14日以上アクセスのないもの)
# /tmp/pr-conflict-check/<owner>-<repo>/ が対象。prompts/ は除外
SHALLOW_ROOT="/tmp/pr-conflict-check"
if [ -d "$SHALLOW_ROOT" ]; then
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    log "removing stale shallow clone: $dir"
    rm -rf "$dir"
  done < <(find "$SHALLOW_ROOT" -mindepth 1 -maxdepth 1 -type d -not -name prompts -atime +14 2>/dev/null)
fi

# 自分のopen PR (非draft) を取得
PRS_JSON=$(gh search prs --author=@me --state=open --draft=false \
  --json url,repository,number,title \
  --limit 50 2>>"$LOG_FILE") || {
  log "ERROR: gh search prs failed"
  exit 1
}

# 単発指定があれば filter
if [ -n "$TARGET_PR" ]; then
  PRS_JSON=$(echo "$PRS_JSON" | jq -c --arg t "$TARGET_PR" \
    '[.[] | select((.repository.nameWithOwner + "#" + (.number|tostring)) == $t)]')
fi

PR_COUNT=$(echo "$PRS_JSON" | jq 'length')
log "Found $PR_COUNT open PR(s) authored by @me"

N_OK=0
N_AUTO=0
N_HUMAN=0
N_ERR=0
SUMMARY=""

while IFS= read -r pr; do
  [ -z "$pr" ] && continue
  REPO=$(echo "$pr" | jq -r '.repository.nameWithOwner')
  NUM=$(echo "$pr" | jq -r '.number')
  URL=$(echo "$pr" | jq -r '.url')
  TITLE=$(echo "$pr" | jq -r '.title')

  # mergeable / mergeStateStatus は gh search では取れないので gh pr view で取得
  PR_DETAIL=$(gh pr view "$NUM" -R "$REPO" \
    --json headRefName,mergeable,mergeStateStatus,baseRefName 2>>"$LOG_FILE") || {
    log "[$REPO#$NUM] ERROR: gh pr view failed"
    N_ERR=$((N_ERR+1))
    SUMMARY+="✗ $REPO#$NUM (gh pr view failed)\n"
    continue
  }

  BRANCH=$(echo "$PR_DETAIL" | jq -r '.headRefName')
  BASE=$(echo "$PR_DETAIL" | jq -r '.baseRefName')
  MERGEABLE=$(echo "$PR_DETAIL" | jq -r '.mergeable')
  STATE=$(echo "$PR_DETAIL" | jq -r '.mergeStateStatus')

  log "[$REPO#$NUM] mergeable=$MERGEABLE state=$STATE branch=$BRANCH base=$BASE"

  # ケースA: コンフリクトなし
  if [ "$MERGEABLE" != "CONFLICTING" ] && [ "$STATE" != "DIRTY" ]; then
    log "  → SKIP (clean)"
    N_OK=$((N_OK+1))
    SUMMARY+="✓ $REPO#$NUM (clean)\n"
    continue
  fi

  # dry-run: 検出のみ
  if [ "$DRY_RUN" = "1" ]; then
    log "  → [dry-run] would invoke pr-conflict-resolve"
    SUMMARY+="? $REPO#$NUM (dry-run, conflict)\n"
    continue
  fi

  # サブスクリプトに委譲。stdout の最終行が結果コード
  log "  → invoking pr-conflict-resolve"
  RESOLVE_OUT=$(/Users/yusukemaruyama/.local/bin/pr-conflict-resolve \
    --repo "$REPO" --number "$NUM" --url "$URL" \
    --branch "$BRANCH" --base "$BASE" --title "$TITLE" 2>>"$LOG_FILE") || true

  RESULT=$(echo "$RESOLVE_OUT" | tail -1)

  case "$RESULT" in
    AUTO_FIXED)
      N_AUTO=$((N_AUTO+1))
      SUMMARY+="✓ $REPO#$NUM (auto-fixed)\n"
      ;;
    HUMAN_NEEDED)
      N_HUMAN=$((N_HUMAN+1))
      SUMMARY+="! $REPO#$NUM (zellij tab opened)\n"
      ;;
    *)
      N_ERR=$((N_ERR+1))
      SUMMARY+="✗ $REPO#$NUM (error: $RESULT)\n"
      ;;
  esac
done < <(echo "$PRS_JSON" | jq -c '.[]')

log "Summary: ok=$N_OK auto=$N_AUTO human=$N_HUMAN err=$N_ERR"
log "Details:
$(echo -e "$SUMMARY")"

# macOS 通知 (1回だけ)
NOTIFIER=/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier
if [ "$DRY_RUN" != "1" ] && [ -x "$NOTIFIER" ]; then
  TOTAL=$((N_OK + N_AUTO + N_HUMAN + N_ERR))
  if [ "$N_HUMAN" -gt 0 ] || [ "$N_ERR" -gt 0 ]; then
    SUBTITLE="$N_HUMAN need review / $N_ERR error / $N_AUTO auto / $N_OK clean"
  else
    SUBTITLE="$TOTAL PR(s) all clean ($N_AUTO auto-fixed)"
  fi
  "$NOTIFIER" \
    --type banner --title "PR Conflict Check" \
    --subtitle "$SUBTITLE" \
    --message "$(echo -e "$SUMMARY" | head -10)" \
    >> "$LOG_FILE" 2>&1 || true
fi

log "=== Done ==="
