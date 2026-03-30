#!/usr/bin/env bash
set -euo pipefail

URL="$1"
NUMBER="$2"
REPO="$3"

echo "🔍 Reviewing PR #${NUMBER} in ${REPO}..."
echo ""

# Step 1: claude -p でレビュー実行、結果を表示
claude --dangerously-skip-permissions -p "/review ${URL}" 2>&1
echo ""

# Step 2: 選択肢を提示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [a] Approve this PR"
echo "  [d] Discuss with Claude Code"
echo "  [o] Open in browser"
echo "  [q] Quit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -r -p "Choose action: " choice

case "$choice" in
  a)
    gh pr review "$NUMBER" -R "$REPO" --approve --body "LGTM 👍 (Reviewed by Claude Code)"
    echo "✅ Approved!"
    ;;
  d)
    exec claude --dangerously-skip-permissions \
      "PR #${NUMBER} (${REPO}) について議論しましょう。URL: ${URL}"
    ;;
  o)
    open "$URL"
    ;;
  q)
    exit 0
    ;;
esac
