#!/usr/bin/env bash
# Stop hook: レビュー指摘に対応して push したのに、再レビュー依頼を出さないまま
# ターンを終えようとしたら一度だけ止めて突き返す。
#
# 判定は「レビュー後に head が進んだのに、そのレビュアーが requested reviewers に
# 戻っていない」こと。APPROVED は対象外（追加の確認を求めるかは人の判断）。
# Copilot 以外の bot は reviewer に指定し直せないので対象外。
#
# このセッションで git push していなければ gh を叩かずに抜ける。同じ head では
# 二度止めない（不要と判断して終えたらそのまま通る）。

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

payload=$(cat)

# 止めた直後の再停止はそのまま通す（無限ループ防止）
[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // ""')
[ -f "$transcript" ] && grep -q 'git push' "$transcript" || exit 0

cwd=$(printf '%s' "$payload" | jq -r '.cwd // ""')
cd "${cwd:-$PWD}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

pr=$(gh pr view --json url,state --jq 'select(.state == "OPEN") | .url' 2>/dev/null)
[ -n "$pr" ] || exit 0
# https://github.com/<owner>/<repo>/pull/<number>
IFS=/ read -r _ _ _ owner repo _ number <<<"$pr"

result=$(gh api graphql \
  -F owner="$owner" -F repo="$repo" -F number="$number" \
  -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  viewer { login }
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      headRefOid
      reviewRequests(first: 50) {
        nodes { requestedReviewer { ... on User { login } ... on Bot { login } } }
      }
      latestReviews(first: 50) {
        nodes { author { __typename login } state commit { oid } }
      }
    }
  }
}' 2>/dev/null) || exit 0

head=$(printf '%s' "$result" | jq -r '.data.repository.pullRequest.headRefOid')

stamp="${TMPDIR:-/tmp}/claude-rereview-guard-$owner-$repo-$number-$head"
[ -f "$stamp" ] && exit 0

# login<TAB>state<TAB>レビュー時の commit（短縮）
pending=$(printf '%s' "$result" | jq -r '
  .data.viewer.login as $me
  | .data.repository.pullRequest as $pr
  | [$pr.reviewRequests.nodes[].requestedReviewer.login // empty] as $requested
  | $pr.latestReviews.nodes[]
  | select(.author.login != $me)
  | select(.state == "CHANGES_REQUESTED" or .state == "COMMENTED")
  | select(.commit.oid != $pr.headRefOid)
  | select(.author.__typename == "User" or .author.login == "copilot-pull-request-reviewer")
  | select(.author.login as $l | $requested | index($l) | not)
  | "\(.author.login)\t\(.state)\t\(.commit.oid[0:7])"
')
[ -n "$pending" ] || exit 0
: >"$stamp"

users=$(printf '%s\n' "$pending" | awk -F'\t' '$1 != "copilot-pull-request-reviewer" { print $1 }' | paste -sd, -)
has_copilot=$(printf '%s\n' "$pending" | awk -F'\t' '$1 == "copilot-pull-request-reviewer" { print "yes" }')

reason=$(
  echo "$owner/$repo#$number は head (${head:0:7}) がレビュー後に進んでいますが、次のレビュアーに再レビュー依頼が出ていません。"
  printf '%s\n' "$pending" | awk -F'\t' '{ printf "  - %s（%s @ %s）\n", $1, $2, $3 }'
  echo
  echo "レビュー指摘への対応を push したなら、終える前に再レビューを依頼してください:"
  [ -n "$users" ] && echo "  gh pr edit $number --repo $owner/$repo --add-reviewer $users"
  [ -n "$has_copilot" ] &&
    echo "  gh api repos/$owner/$repo/pulls/$number/requested_reviewers -f 'reviewers[]=copilot-pull-request-reviewer[bot]'"
  echo
  echo "指摘への対応ではない push などで不要なら、その旨をユーザーに一言伝えて終えてください（この head では二度は止めません）。"
)

jq -n --arg reason "$reason" '{ decision: "block", reason: $reason }'
