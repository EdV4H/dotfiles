#!/usr/bin/env bash
# PostToolUse(Bash) hook: gh pr create / gh pr ready で PR が出たら auto-merge を有効にする。
#
# 有効化は GraphQL の enablePullRequestAutoMerge で行う。`gh pr merge --auto` は
# すでにマージ可能な PR だとその場でマージしてしまうことがあるため使わない。
# マージ方法はリポジトリでの viewer の既定 (viewerDefaultMergeMethod)。
#
# 有効にできなかったとき (repo で未許可 / draft / 保護ルールが無い等) は理由を
# Claude に返すだけで、作業は止めない。

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

payload=$(cat)

cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
case "$cmd" in
*"gh pr create"* | *"gh pr ready"*) ;;
*) exit 0 ;;
esac

out=$(printf '%s' "$payload" | jq -r '[.tool_response.stdout // "", .tool_response.stderr // ""] | join("\n")')

# gh pr create は URL を、gh pr ready は owner/repo#N を出す
if ref=$(printf '%s' "$out" | grep -oE 'https://github\.com/[^/[:space:]]+/[^/[:space:]]+/pull/[0-9]+' | tail -1) && [ -n "$ref" ]; then
  IFS=/ read -r _ _ _ owner repo _ number <<<"$ref"
elif ref=$(printf '%s' "$out" | grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' | tail -1) && [ -n "$ref" ]; then
  owner=${ref%%/*}
  repo=${ref#*/}
  repo=${repo%%#*}
  number=${ref##*#}
else
  exit 0
fi

reply() {
  jq -n --arg ctx "$1" '{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'
  exit 0
}

info=$(gh api graphql \
  -F owner="$owner" -F repo="$repo" -F number="$number" \
  -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    autoMergeAllowed
    viewerDefaultMergeMethod
    pullRequest(number: $number) { id state isDraft autoMergeRequest { mergeMethod } }
  }
}' 2>&1) || reply "$owner/$repo#$number の auto-merge を確認できませんでした: $info"

pr_id=$(printf '%s' "$info" | jq -r '.data.repository.pullRequest.id')
method=$(printf '%s' "$info" | jq -r '.data.repository.viewerDefaultMergeMethod')

[ "$(printf '%s' "$info" | jq -r '.data.repository.pullRequest.state')" = "OPEN" ] || exit 0
[ "$(printf '%s' "$info" | jq -r '.data.repository.pullRequest.autoMergeRequest != null')" = "true" ] && exit 0

[ "$(printf '%s' "$info" | jq -r '.data.repository.autoMergeAllowed')" = "true" ] ||
  reply "$owner/$repo#$number: このリポジトリは auto-merge を許可していないので有効にしていません。ユーザーにそう伝えてください。"

[ "$(printf '%s' "$info" | jq -r '.data.repository.pullRequest.isDraft')" = "true" ] &&
  reply "$owner/$repo#$number は draft なので auto-merge はまだ有効にしていません。gh pr ready で Ready for review にすればこの hook が有効にします。"

result=$(gh api graphql \
  -F prId="$pr_id" -F method="$method" \
  -f query='
mutation($prId: ID!, $method: PullRequestMergeMethod!) {
  enablePullRequestAutoMerge(input: { pullRequestId: $prId, mergeMethod: $method }) {
    pullRequest { autoMergeRequest { mergeMethod } }
  }
}' 2>&1)

if [ "$(printf '%s' "$result" | jq -r '.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest != null' 2>/dev/null)" = "true" ]; then
  reply "$owner/$repo#$number の auto-merge を有効にしました（$method）。ユーザーへの報告に含めてください。"
fi

reason=$(printf '%s' "$result" | jq -r '[.errors[]?.message] | join(" / ")' 2>/dev/null)
reply "$owner/$repo#$number の auto-merge を有効にできませんでした: ${reason:-$result}。ユーザーにそう伝えてください（自分で gh pr merge を叩いてマージしないこと）。"
