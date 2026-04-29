#!/usr/bin/env bash
set -euo pipefail

URL="$1"
NUMBER="$2"
REPO="$3"

echo "🔍 Reviewing PR #${NUMBER} in ${REPO}..."
echo ""

# Step 1: claude -p でレビュー実行、結果を保存＆表示
REVIEW_RESULT=$(claude --dangerously-skip-permissions -p "/review ${URL}" 2>&1)
echo "$REVIEW_RESULT"
echo ""

# 分析完了後、このレビュータブにフォーカスを移動
zellij action go-to-tab-name "Review: ${REPO}#${NUMBER}" 2>/dev/null || true

# Step 2: 選択肢を提示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [a] Approve this PR"
echo "  [c] Comment concerns as pending review (open in browser)"
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
  c)
    echo "🤖 Extracting concerns as inline comments..."
    OWNER="${REPO%/*}"
    REPO_NAME="${REPO#*/}"
    COMMIT_ID=$(gh pr view "$NUMBER" -R "$REPO" --json headRefOid -q '.headRefOid')
    DIFF=$(gh pr diff "$NUMBER" -R "$REPO")

    # diffをパースして各行に絶対行番号を付与（Claudeが行番号を計算する必要をなくす）
    # +行とコンテキスト行（スペース始まり）の両方にアノテーションを付ける
    # GitHub APIはdiff内のコンテキスト行にもコメントできるため
    ANNOTATED_DIFF=$(echo "$DIFF" | awk '
      /^diff --git/ { file="" }
      /^\+\+\+ / { file=substr($0, 7); print; next }
      /^--- / { print; next }
      /^@@ / {
        s = $0
        sub(/^@@ -[0-9,]+ \+/, "", s)
        sub(/,.*/, "", s)
        newline = s + 0
        print
        next
      }
      file != "" && /^[-+ ]/ {
        prefix = substr($0, 1, 1)
        if (prefix == "-") {
          print
        } else if (prefix == "+") {
          printf "[LINE %d] %s\n", newline, $0
          newline++
        } else {
          printf "[LINE %d] %s\n", newline, $0
          newline++
        }
        next
      }
      { print }
    ')

    COMMENTS_JSON=$(claude --dangerously-skip-permissions -p "以下はPRの annotated diff と事前レビュー結果です。レビュー結果に挙がっている懸念事項を、該当する行への inline review comment として JSON 配列で出力してください。

出力形式（この形式のJSON配列のみ、余計なテキストなし、コードフェンスなし）:
[{\"path\": \"src/foo.ts\", \"line\": 42, \"side\": \"RIGHT\", \"body\": \"懸念内容\"}]

- path: 変更されたファイルのパス（+++ b/... のパス。先頭の b/ は除く）
- line: [LINE N] タグに記載された番号をそのまま使うこと。自分で計算しないでください。
- side: 常に \"RIGHT\"
- body: 懸念事項の内容（日本語で簡潔に）
- 懸念事項がなければ空配列 []

重要: 各追加行(+)とコンテキスト行(スペース始まり)の先頭に [LINE N] タグが付いています。この N が変更後ファイルの絶対行番号です。必ずこの番号をそのまま使ってください。削除行(-)にはタグがありません。

--- ANNOTATED DIFF ---
${ANNOTATED_DIFF}

--- REVIEW ---
${REVIEW_RESULT}")

    # 余計な装飾を除去
    COMMENTS_JSON=$(echo "$COMMENTS_JSON" | sed -n '/^\[/,/^\]/p')

    if [[ -z "$COMMENTS_JSON" || "$COMMENTS_JSON" == "[]" ]]; then
      echo "ℹ️  懸念事項は抽出されませんでした。"
      exit 0
    fi

    echo "$COMMENTS_JSON" | jq .

    # pending review を作成（event を指定しないと pending になる）
    PAYLOAD=$(jq -n --arg commit "$COMMIT_ID" --argjson comments "$COMMENTS_JSON" \
      '{commit_id: $commit, comments: $comments}')

    echo "$PAYLOAD" | gh api "repos/${OWNER}/${REPO_NAME}/pulls/${NUMBER}/reviews" \
      --method POST --input - > /dev/null

    echo "✅ Pending review created. Opening browser..."
    open "${URL}/files"
    ;;
  d)
    exec claude --dangerously-skip-permissions \
      "PR #${NUMBER} (${REPO}) について議論しましょう。URL: ${URL}

以下はClaude Codeによる事前レビュー結果です:

${REVIEW_RESULT}"
    ;;
  o)
    open "$URL"
    ;;
  q)
    exit 0
    ;;
esac
