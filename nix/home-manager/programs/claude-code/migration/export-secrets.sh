#!/usr/bin/env bash
set -euo pipefail

# PC 移行: 旧 PC 側で gitignored の機密設定 + ~/.ssh などを tar.gz に固める。
# DRY_RUN=1 で実際の tar 作成はせず、対象一覧と合計サイズだけ表示。
#
# 出力:
#   ~/migration-bundle-<ts>.tar.gz
#   ~/migration-bundle-<ts>.tar.gz.sha256
#   ~/migration-bundle-<ts>.filelist.txt  (デバッグ用、入っているファイル一覧)

DRY_RUN="${MIGRATION_DRY_RUN:-0}"
TS=$(date '+%Y%m%d-%H%M%S')
BUNDLE_DIR="$HOME"
BUNDLE_BASE="migration-bundle-$TS"
BUNDLE_TAR="$BUNDLE_DIR/$BUNDLE_BASE.tar.gz"
FILELIST="$BUNDLE_DIR/$BUNDLE_BASE.filelist.txt"
PROJECTS_ROOT="$HOME/Projects"

# 1ファイル当たり許容サイズ上限 (10MB)。 これを超えるものは tar に入れない (誤検出ガード)。
MAX_FILE_BYTES=$((10 * 1024 * 1024))

# 対象ファイル名パターン (basename glob、 case sensitive)
# 注意: `*.key` `*.pem` は秘密鍵想定。 `*.pub` は除外。
read -r -d '' INCLUDE_BASENAME_GLOBS <<'EOF' || true
.env
.env.*
.envrc
.npmrc
.yarnrc
.yarnrc.yml
.nvmrc
.ruby-version
.tool-versions
.secrets
*.pem
*.key
EOF

# 対象 path パターン (relative path glob、 案件によって repo 内の特定 path のみ持っていきたいもの)
read -r -d '' INCLUDE_PATH_GLOBS <<'EOF' || true
.vscode/settings.json
.vscode/launch.json
.vscode/tasks.json
.claude/settings.local.json
EOF

# 除外パターン (false positive 対策)
# - *.pub: SSH 公開鍵
# - *.sample / *.example / *.template / *.tmpl: 公開テンプレート (秘密情報なし、 git で取れる)
# - .env.*.sample, .env.*.example: 上記の派生
read -r -d '' EXCLUDE_BASENAME_GLOBS <<'EOF' || true
*.pub
*.pub.key
*.example
*.sample
*.template
*.tmpl
*.sample.*
*.example.*
EOF

log() {
  echo "[$(date '+%H:%M:%S')] $*" >&2
}

match_glob() {
  # $1: file basename or relpath / $2: newline-separated glob list
  local name="$1"
  local globs="$2"
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    case "$name" in
      $g) return 0 ;;
    esac
  done <<<"$globs"
  return 1
}

# ~/Projects/ 配下を直接 find で walk して whitelist ファイルだけ抽出する。
# 旧実装は `git ls-files --others --ignored --exclude-standard` を使っていたが、
# monorepo + node_modules を含めると数百万エントリ返ってきて事実上ハングする。
# whitelist は basename ベースで決まるため、find -name で大量に枝刈りすれば十分。
#
# 除外:
#   - .git ディレクトリ全体
#   - node_modules, .next, dist, build, target, .turbo, .cache, .gradle, vendor
collect_repo_secrets() {
  [ -d "$PROJECTS_ROOT" ] || return 0

  # find 引数: -name で whitelist の basename + -path で個別 path
  # まず除外パターンを prune するため find 全体を組み立てる
  find "$PROJECTS_ROOT" \
    \( \
      -type d \( \
        -name .git -o \
        -name node_modules -o \
        -name .next -o \
        -name dist -o \
        -name build -o \
        -name target -o \
        -name .turbo -o \
        -name .cache -o \
        -name .gradle -o \
        -name vendor -o \
        -name .venv -o \
        -name venv -o \
        -name __pycache__ \
      \) -prune \
    \) \
    -o \
    \( -type f \( \
      -name '.env' -o \
      -name '.env.*' -o \
      -name '.envrc' -o \
      -name '.npmrc' -o \
      -name '.yarnrc' -o \
      -name '.yarnrc.yml' -o \
      -name '.nvmrc' -o \
      -name '.ruby-version' -o \
      -name '.tool-versions' -o \
      -name '.secrets' -o \
      -name '*.pem' -o \
      -name '*.key' \
    \) -print \) \
    -o \
    \( -type f \( \
      -path '*/.vscode/settings.json' -o \
      -path '*/.vscode/launch.json' -o \
      -path '*/.vscode/tasks.json' -o \
      -path '*/.claude/settings.local.json' \
    \) -print \) \
    2>/dev/null \
  | while IFS= read -r abspath; do
      [ -z "$abspath" ] && continue
      local basename="${abspath##*/}"
      # 除外パターン (例: id_ed25519.pub などはここで弾く)
      if match_glob "$basename" "$EXCLUDE_BASENAME_GLOBS"; then
        continue
      fi
      # サイズ上限
      local size
      size=$(stat -f%z "$abspath" 2>/dev/null || stat -c%s "$abspath" 2>/dev/null || echo 0)
      if [ "$size" -gt "$MAX_FILE_BYTES" ]; then
        log "skip (size $size > limit): $abspath"
        continue
      fi
      echo "$abspath"
    done
}

# 固定で持ち出すパス (存在すれば追加)
collect_fixed_paths() {
  local p
  for p in \
    "$HOME/.ssh" \
    "$HOME/.cache/pr-conflict-check" \
    "$HOME/.zprofile.kiro.bak" \
    "$HOME/.zsh_history"
  do
    if [ -e "$p" ]; then
      echo "$p"
    fi
  done
}

log "collecting paths..."
TMP_LIST=$(mktemp -t migration-export.XXXXXX)
trap 'rm -f "$TMP_LIST"' EXIT

# repo 配下の secret
collect_repo_secrets > "$TMP_LIST"
REPO_COUNT=$(wc -l < "$TMP_LIST" | tr -d ' ')
log "found $REPO_COUNT repo-scoped secret file(s)"

# 固定パス追加
collect_fixed_paths >> "$TMP_LIST"
TOTAL_COUNT=$(wc -l < "$TMP_LIST" | tr -d ' ')
log "total $TOTAL_COUNT path(s) to bundle"

# 合計サイズ
TOTAL_BYTES=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  bytes=""
  if [ -d "$p" ]; then
    bytes=$(find "$p" -type f -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s+0}') || bytes=0
  else
    bytes=$(stat -f%z "$p" 2>/dev/null) || bytes=$(stat -c%s "$p" 2>/dev/null) || bytes=0
  fi
  # 空文字 / 非数値ガード
  [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
  TOTAL_BYTES=$((TOTAL_BYTES + bytes))
done < "$TMP_LIST"

human_size() {
  local b=$1
  if [ "$b" -lt 1024 ]; then echo "${b}B"
  elif [ "$b" -lt 1048576 ]; then echo "$((b / 1024))KB"
  elif [ "$b" -lt 1073741824 ]; then echo "$((b / 1048576))MB"
  else echo "$((b / 1073741824))GB"
  fi
}

log "total size: $(human_size "$TOTAL_BYTES")"

if [ "$DRY_RUN" = "1" ]; then
  echo ""
  echo "=== DRY RUN: 下記が bundle に含まれる予定 ==="
  cat "$TMP_LIST"
  echo "==="
  echo "files: $TOTAL_COUNT  total: $(human_size "$TOTAL_BYTES")"
  echo ""
  echo "実際に作成するには MIGRATION_DRY_RUN=0 (or unset) で再実行してください。"
  exit 0
fi

# tar 作成 (path を保ったまま絶対 path で)
log "creating tar: $BUNDLE_TAR"
# macOS の bsdtar (libarchive) を想定。 -T <file> でファイル一覧、 -c -z -f で create+gzip。
# GNU tar の `--no-recursion=false` や `--ignore-failed-read` は bsdtar 非対応なので使わない。
# (bsdtar はデフォルトで読めないファイルは warn のみで継続)
tar -czf "$BUNDLE_TAR" -T "$TMP_LIST"

# filelist を保存 (デバッグ + restore 側で参照可)
cp "$TMP_LIST" "$FILELIST"

# SHA256
log "computing sha256..."
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$BUNDLE_TAR" > "$BUNDLE_TAR.sha256"
else
  sha256sum "$BUNDLE_TAR" > "$BUNDLE_TAR.sha256"
fi

echo ""
echo "=== Export 完了 ==="
echo "  bundle:   $BUNDLE_TAR"
echo "  sha256:   $BUNDLE_TAR.sha256"
echo "  filelist: $FILELIST"
echo "  size:     $(human_size "$TOTAL_BYTES") (compressed: $(human_size "$(stat -f%z "$BUNDLE_TAR" 2>/dev/null || stat -c%s "$BUNDLE_TAR")"))"
echo ""
echo "次のステップ: list-repos.sh で repos.txt を作り、両方を AirDrop or scp で新 PC へ。"
