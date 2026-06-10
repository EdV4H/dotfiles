#!/usr/bin/env bash
set -euo pipefail

# PC 移行: 新 PC 側で bundle を展開し、repos.txt を読んで GitHub から再 clone する。
#
# usage:
#   migration-restore <bundle.tar.gz> <repos.txt>
#
# env:
#   MIGRATION_TARGET=/tmp/x  ... 展開先の root を $HOME 以外にして dry-test できる

BUNDLE="${1:-}"
REPOS_TXT="${2:-}"
TARGET="${MIGRATION_TARGET:-/}"

if [ -z "$BUNDLE" ] || [ -z "$REPOS_TXT" ]; then
  cat >&2 <<EOF
usage: $(basename "$0") <bundle.tar.gz> <repos.txt>

引数:
  bundle.tar.gz  export-secrets.sh の出力した tar.gz
  repos.txt      list-repos.sh の出力した TSV

env:
  MIGRATION_TARGET=/tmp/x   展開先を変えてテスト (default: /)
EOF
  exit 2
fi

[ -f "$BUNDLE" ]   || { echo "bundle not found: $BUNDLE" >&2; exit 1; }
[ -f "$REPOS_TXT" ] || { echo "repos.txt not found: $REPOS_TXT" >&2; exit 1; }

log() {
  echo "[$(date '+%H:%M:%S')] $*"
}

# 1. SHA256 検証 (.sha256 が同階層にあれば)
SHA_FILE="$BUNDLE.sha256"
if [ -f "$SHA_FILE" ]; then
  log "verifying sha256..."
  if command -v shasum >/dev/null 2>&1; then
    (cd "$(dirname "$BUNDLE")" && shasum -a 256 -c "$(basename "$SHA_FILE")")
  else
    (cd "$(dirname "$BUNDLE")" && sha256sum -c "$(basename "$SHA_FILE")")
  fi
else
  log "warn: $SHA_FILE not found, skipping sha verification"
fi

# 2. tar 展開 (mode 保持)
log "extracting bundle into $TARGET ..."
mkdir -p "$TARGET"
tar -xzpf "$BUNDLE" -C "$TARGET"

# 3. ~/.ssh の権限を矯正
SSH_DIR="$TARGET/$HOME/.ssh"
# MIGRATION_TARGET=/ の場合は $TARGET/$HOME が //Users/... になるのを避けるため、 path normalize
SSH_DIR=$(echo "$SSH_DIR" | sed 's|//|/|g')
if [ -d "$SSH_DIR" ]; then
  log "fixing permissions on $SSH_DIR"
  chmod 700 "$SSH_DIR" || true
  find "$SSH_DIR" -maxdepth 1 -type f \( -name 'id_*' -not -name '*.pub' -o -name 'config' -o -name 'allowed_signers' \) \
    -exec chmod 600 {} + 2>/dev/null || true
  find "$SSH_DIR" -maxdepth 1 -type f \( -name '*.pub' -o -name 'known_hosts' \) \
    -exec chmod 644 {} + 2>/dev/null || true
fi

# 4. repos を loop clone (MIGRATION_TARGET が / のときだけ。 そうでなければスキップ)
if [ "$TARGET" = "/" ]; then
  log "cloning repos from $REPOS_TXT ..."
  FAILED_REPOS="$HOME/migration-failed-repos.txt"
  : > "$FAILED_REPOS"
  cloned=0
  skipped=0
  failed=0
  while IFS=$'\t' read -r relpath url; do
    [ -z "$relpath" ] && continue
    [ -z "$url" ] && continue
    abspath="$HOME/$relpath"
    if [ -d "$abspath/.git" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    mkdir -p "$(dirname "$abspath")"
    if gh repo clone "$url" "$abspath" >/dev/null 2>&1; then
      cloned=$((cloned + 1))
      echo "  cloned: $relpath"
    else
      echo "$relpath"$'\t'"$url" >> "$FAILED_REPOS"
      failed=$((failed + 1))
      echo "  FAILED: $relpath  ($url)"
    fi
  done < "$REPOS_TXT"

  log "clone done: cloned=$cloned skipped=$skipped failed=$failed"
  if [ "$failed" -gt 0 ]; then
    echo "  failed repos recorded to: $FAILED_REPOS"
    echo "  (`gh auth login` を済ませた後、手動で clone してください)"
  fi
else
  log "MIGRATION_TARGET=$TARGET (not /). repos clone をスキップ"
fi

# 5. 案内
cat <<'EOF'

═══════════════════════════════════════════════════════════════════
✅ Restore 完了

次のステップ:

1. 認証を順番に通す:
     gh auth login
     aws sso login --profile <profile>           # profile ごとに
     gcloud auth login
     gcloud auth application-default login
     docker login

2. failed-repos があれば gh auth 後に再 clone:
     while IFS=$'\t' read -r p u; do
       mkdir -p "$(dirname "$HOME/$p")" && gh repo clone "$u" "$HOME/$p"
     done < ~/migration-failed-repos.txt

3. 必要な node バージョンを Volta で入れ直す:
     volta install node@<version>

4. Kiro CLI を使うなら退避された .zprofile を戻す:
     [ -f ~/.zprofile.kiro.bak ] && mv ~/.zprofile ~/.zprofile.hm.bak && mv ~/.zprofile.kiro.bak ~/.zprofile

5. 各 repo で `pnpm install` (or 該当 package manager) を実行
═══════════════════════════════════════════════════════════════════
EOF
