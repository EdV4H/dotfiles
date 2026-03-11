#!/usr/bin/env bash
ROLE=${CLAUDE_ROLE:-$(basename "$PWD")}
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier \
  --type banner \
  --title "$ROLE" \
  --subtitle "タスク完了" \
  --message "${ROLE}のタスクが完了しました" \
  --sound default \
  --messageaction "/usr/bin/open /Applications/WezTerm.app"
