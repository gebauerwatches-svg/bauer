#!/usr/bin/env bash
# Bauer backup script
# Copies your local Bauer state to a timestamped folder.
#
# Usage:  bash scripts/backup.sh
# Optionally:  BAUER_BACKUP_DIR=~/Dropbox/bauer-backups bash scripts/backup.sh

set -euo pipefail

BACKUP_DIR="${BAUER_BACKUP_DIR:-$HOME/Documents/bauer-backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$BACKUP_DIR/$STAMP"

mkdir -p "$TARGET"

# 1. Your ~/.claude/ — includes CLAUDE.md, all skills, AND any custom agents you've built
if [ -d "$HOME/.claude" ]; then
    cp -R "$HOME/.claude" "$TARGET/claude"
    echo "✓ Backed up ~/.claude → $TARGET/claude"
fi

# 2. The Ollama bridge config (open-source path)
if [ -d "$HOME/.claude-code-router" ]; then
    cp -R "$HOME/.claude-code-router" "$TARGET/claude-code-router"
    echo "✓ Backed up ~/.claude-code-router → $TARGET/claude-code-router"
fi

# 3. Notes file: which models you have, what Claude version, etc.
cat > "$TARGET/notes.txt" <<EOF
Bauer backup
Date: $(date)
Hostname: $(hostname)

Claude Code version:
$(claude --version 2>/dev/null || echo "  (not installed or not on PATH)")

Ollama models present:
$(ollama list 2>/dev/null || echo "  (Ollama not installed)")

Git repo HEAD (Bauer source):
$(git -C "$HOME/bauer-project" log -1 --oneline 2>/dev/null || echo "  (repo not at expected path)")
EOF
echo "✓ Wrote backup notes → $TARGET/notes.txt"

echo ""
echo "Backup complete: $TARGET"
echo ""
echo "💡  Tip: put BAUER_BACKUP_DIR in an iCloud / Dropbox / Google Drive folder"
echo "   so backups go off-machine automatically. Example:"
echo "   BAUER_BACKUP_DIR=~/Library/Mobile\\ Documents/com~apple~CloudDocs/bauer-backups bash scripts/backup.sh"
