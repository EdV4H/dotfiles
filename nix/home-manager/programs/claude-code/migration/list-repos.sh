#!/usr/bin/env bash
set -euo pipefail

# PC 移行: 旧 PC 側で ~/Projects/ 配下の git リポジトリ remote URL を TSV で書き出す。
# 新 PC では restore.sh がこれを読んでループ clone する。
#
# 出力: ~/migration-bundle-<ts>.repos.txt
#   <home_relative_path>\t<remote_url>
#
# - .git が **ディレクトリ** のものだけ列挙 (worktree (.git が file) は除外)
# - origin remote が無いリポジトリは fail-list に記録

TS="${MIGRATION_TS:-$(date '+%Y%m%d-%H%M%S')}"
OUT="$HOME/migration-bundle-$TS.repos.txt"
FAIL_OUT="$HOME/migration-bundle-$TS.repos-skipped.txt"
PROJECTS_ROOT="$HOME/Projects"

: > "$OUT"
: > "$FAIL_OUT"

count=0
skipped=0

[ -d "$PROJECTS_ROOT" ] || {
  echo "no $PROJECTS_ROOT directory; nothing to list" >&2
  exit 0
}

while IFS= read -r gitdir; do
  [ -z "$gitdir" ] && continue
  [ -d "$gitdir" ] || continue  # worktree skip
  repo="${gitdir%/.git}"
  # ~/ 始まりの相対化
  case "$repo" in
    "$HOME"/*) relpath="${repo#$HOME/}" ;;
    *)         relpath="$repo" ;;
  esac

  url=$(git -C "$repo" remote get-url origin 2>/dev/null || true)
  if [ -z "$url" ]; then
    echo "$relpath" >> "$FAIL_OUT"
    skipped=$((skipped + 1))
    continue
  fi

  printf '%s\t%s\n' "$relpath" "$url" >> "$OUT"
  count=$((count + 1))
done < <(find "$PROJECTS_ROOT" -maxdepth 5 -name .git -type d 2>/dev/null | sort)

echo ""
echo "=== Repos 列挙完了 ==="
echo "  output:  $OUT  ($count repos)"
if [ "$skipped" -gt 0 ]; then
  echo "  skipped: $FAIL_OUT  ($skipped repos without origin)"
fi
echo ""
echo "次のステップ: export-secrets.sh で bundle を作り、両方を新 PC へ転送。"
