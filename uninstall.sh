#!/bin/bash
set -e

# ============================================================================
# Claude Code Setup - Uninstall
# ============================================================================
# Reverts config changes made by install.sh
# Does NOT uninstall Claude Code itself
# ============================================================================

CLAUDE_DIR="$HOME/.claude"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "============================================"
echo "  Claude Code Setup - Uninstall"
echo "============================================"
echo ""
echo "Ceci va supprimer :"
echo "  - ~/.claude/CLAUDE.md"
echo "  - ~/.claude/scripts/session-resume.sh"
echo "  - Le hook session-resume de settings.json"
echo ""
echo "Ceci ne supprime PAS :"
echo "  - Claude Code CLI"
echo "  - Les plugins (desinstallez-les manuellement avec 'claude plugins uninstall')"
echo "  - Vos autres settings/hooks"
echo ""
echo -n "Continuer ? (y/N): "
read -r REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Annule."
    exit 0
fi

# Remove CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    rm "$CLAUDE_DIR/CLAUDE.md"
    success "CLAUDE.md supprime"
else
    warn "CLAUDE.md non trouve"
fi

# Restore backup if exists
LATEST_BACKUP=$(ls -t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    echo -n "  Restaurer le backup ($LATEST_BACKUP) ? (y/N): "
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        cp "$LATEST_BACKUP" "$CLAUDE_DIR/CLAUDE.md"
        success "Backup restaure"
    fi
fi

# Remove session-resume script
if [ -f "$CLAUDE_DIR/scripts/session-resume.sh" ]; then
    rm "$CLAUDE_DIR/scripts/session-resume.sh"
    success "session-resume.sh supprime"
fi

# Remove hook from settings.json
if command -v jq &>/dev/null && [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
    jq '.hooks.UserPromptSubmit[0].hooks = [.hooks.UserPromptSubmit[0].hooks[] | select(.command | contains("session-resume") | not)]' \
        "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp" \
        && mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
    success "Hook session-resume retire de settings.json"
else
    warn "Impossible de modifier settings.json (jq requis). Retirez manuellement le hook session-resume."
fi

echo ""
success "Desinstallation terminee."
echo ""
