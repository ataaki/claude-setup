#!/bin/bash
set -e

# ============================================================================
# Claude Code Setup - Uninstall
# ============================================================================
# Reverts changes made by install.sh
# Can optionally uninstall Claude Code CLI, plugins, and config
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_FILE="$SCRIPT_DIR/config/plugins.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

echo ""
echo "============================================"
echo "  Claude Code Setup - Uninstall"
echo "============================================"
echo ""
echo "  Ceci peut supprimer :"
echo "  - La config installee par le setup (CLAUDE.md, session-resume.sh, hook)"
echo "  - Les plugins installes par le setup"
echo "  - Claude Code CLI lui-meme"
echo ""
echo -n "Continuer ? (y/N): "
read -r REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Annule."
    exit 0
fi

# ============================================================================
# 1. Remove CLAUDE.md (with backup restore option)
# ============================================================================

echo ""
info "--- CLAUDE.md ---"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    rm "$CLAUDE_DIR/CLAUDE.md"
    success "CLAUDE.md supprime"

    # Check for backups (created by install.sh before overwriting)
    LATEST_BACKUP=$(find "$CLAUDE_DIR" -maxdepth 1 -name "CLAUDE.md.backup.*" -type f 2>/dev/null | sort -r | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        echo -n "  Restaurer le backup ($LATEST_BACKUP) ? (y/N): "
        read -r REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            cp "$LATEST_BACKUP" "$CLAUDE_DIR/CLAUDE.md"
            success "Backup restaure"
        fi
    fi
else
    skip "CLAUDE.md non trouve"
fi

# ============================================================================
# 2. Remove session-resume script
# ============================================================================

info "--- session-resume.sh ---"

if [ -f "$CLAUDE_DIR/scripts/session-resume.sh" ]; then
    rm "$CLAUDE_DIR/scripts/session-resume.sh"
    success "session-resume.sh supprime"
else
    skip "session-resume.sh non trouve"
fi

# ============================================================================
# 3. Remove hook from settings.json
# ============================================================================

info "--- Hook settings.json ---"

if command_exists jq && [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
    # Validate JSON and check hooks structure before attempting modification
    if ! jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
        warn "settings.json est malforme. Editez-le manuellement pour retirer le hook session-resume."
    elif jq -e '.hooks.UserPromptSubmit[0].hooks' "$CLAUDE_DIR/settings.json" &>/dev/null; then
        jq '.hooks.UserPromptSubmit[0].hooks = [.hooks.UserPromptSubmit[0].hooks[] | select(.command | contains("session-resume") | not)]' \
            "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp" \
            && mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
        success "Hook session-resume retire de settings.json"
    else
        skip "Aucun hook UserPromptSubmit dans settings.json"
    fi
else
    if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
        skip "settings.json non trouve"
    else
        warn "jq requis pour modifier settings.json. Retirez manuellement le hook session-resume."
    fi
fi

# ============================================================================
# 4. Optionally remove plugins
# WARNING: must run BEFORE section 5 (CLI uninstall) — needs claude command
# ============================================================================

echo ""
echo -n "  Supprimer aussi les plugins installes par le setup ? (y/N): "
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    info "Suppression des plugins..."

    if command_exists claude; then
        # Load plugin list from shared config file
        PLUGINS=()
        if [ -f "$PLUGINS_FILE" ]; then
            while IFS= read -r line || [ -n "$line" ]; do
                [ -z "$line" ] && continue
                [[ "$line" =~ ^# ]] && continue
                PLUGINS+=("$line")
            done < "$PLUGINS_FILE"
        else
            warn "plugins.txt non trouve ($PLUGINS_FILE). Utilisez 'claude plugins list' pour voir les plugins installes."
        fi
        for plugin in "${PLUGINS[@]}"; do
            claude plugins uninstall "$plugin" 2>/dev/null \
                && success "  $plugin supprime" \
                || skip "  $plugin (non installe ou erreur)"
        done
    else
        warn "Claude CLI non disponible. Impossible de desinstaller les plugins via CLI."
        for dir in "$CLAUDE_DIR/plugins" "$CLAUDE_DIR/installed-plugins"; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
                success "Repertoire supprime: $dir"
            fi
        done
    fi
else
    skip "Plugins conserves"
fi

# ============================================================================
# 5. Optionally uninstall Claude Code CLI
# ============================================================================

echo ""
echo -n "  Desinstaller aussi Claude Code CLI ? (y/N): "
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    info "Desinstallation du CLI..."
    UNINSTALLED=false

    if command_exists npm && npm list -g @anthropic-ai/claude-code &>/dev/null; then
        npm uninstall -g @anthropic-ai/claude-code
        success "Claude Code desinstalle (npm)"
        UNINSTALLED=true
    fi

    if command_exists brew && brew list claude-code &>/dev/null; then
        brew uninstall claude-code
        success "Claude Code desinstalle (brew)"
        UNINSTALLED=true
    fi

    if command_exists dpkg && dpkg -s claude-code &>/dev/null 2>&1; then
        sudo apt-get remove -y claude-code 2>/dev/null || sudo dpkg -r claude-code 2>/dev/null
        success "Claude Code desinstalle (apt/dpkg)"
        UNINSTALLED=true
    fi

    if command_exists snap && snap list claude-code &>/dev/null 2>&1; then
        sudo snap remove claude-code
        success "Claude Code desinstalle (snap)"
        UNINSTALLED=true
    fi

    if command_exists winget.exe && winget.exe list --id "Anthropic.Claude" &>/dev/null 2>&1; then
        winget.exe uninstall --id "Anthropic.Claude" --silent 2>/dev/null
        success "Claude Code desinstalle (winget)"
        UNINSTALLED=true
    fi

    if command_exists claude; then
        CLAUDE_BIN=$(command -v claude 2>/dev/null)
        if [ -n "$CLAUDE_BIN" ]; then
            rm -f "$CLAUDE_BIN"
            success "Binaire supprime ($CLAUDE_BIN)"
            UNINSTALLED=true
        fi
    fi

    for p in "$HOME/.local/bin/claude" "$HOME/.claude/bin/claude" "/usr/local/bin/claude"; do
        if [ -f "$p" ]; then
            rm -f "$p"
            success "Binaire supprime ($p)"
            UNINSTALLED=true
        fi
    done

    if [ "$UNINSTALLED" = false ]; then
        warn "Aucune installation de Claude Code trouvee."
    fi
else
    skip "Claude Code CLI conserve"
fi

echo ""
success "Desinstallation terminee."
echo ""
