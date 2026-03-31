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
echo "  This can remove:"
echo "  - Config installed by the setup (CLAUDE.md, session-resume.sh, hook)"
echo "  - Plugins installed by the setup"
echo "  - Claude Code CLI itself"
echo ""
echo -n "Continue? (y/N): "
read -r REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# ============================================================================
# 1. Remove CLAUDE.md (with backup restore option)
# ============================================================================

echo ""
info "--- CLAUDE.md ---"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    rm "$CLAUDE_DIR/CLAUDE.md"
    success "CLAUDE.md removed"

    # Check for backups (created by install.sh before overwriting)
    LATEST_BACKUP=$(find "$CLAUDE_DIR" -maxdepth 1 -name "CLAUDE.md.backup.*" -type f 2>/dev/null | sort -r | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        echo -n "  Restore backup ($LATEST_BACKUP)? (y/N): "
        read -r REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            cp "$LATEST_BACKUP" "$CLAUDE_DIR/CLAUDE.md"
            success "Backup restored"
        fi
    fi
else
    skip "CLAUDE.md not found"
fi

# ============================================================================
# 2. Remove session-resume script
# ============================================================================

info "--- session-resume ---"

if [ -f "$CLAUDE_DIR/scripts/session-resume.sh" ]; then
    rm "$CLAUDE_DIR/scripts/session-resume.sh"
    success "session-resume.sh removed"
else
    skip "session-resume.sh not found"
fi

if [ -f "$CLAUDE_DIR/scripts/session-resume.ps1" ]; then
    rm "$CLAUDE_DIR/scripts/session-resume.ps1"
    success "session-resume.ps1 removed"
fi

# ============================================================================
# 3. Remove hook from settings.json
# ============================================================================

info "--- Hook settings.json ---"

if command_exists jq && [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
    # Validate JSON and check hooks structure before attempting modification
    if ! jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
        warn "settings.json is malformed. Edit manually to remove the session-resume hook."
    elif jq -e '.hooks.UserPromptSubmit[0].hooks' "$CLAUDE_DIR/settings.json" &>/dev/null; then
        jq '.hooks.UserPromptSubmit[0].hooks = [.hooks.UserPromptSubmit[0].hooks[] | select(.command | contains("session-resume") | not)]' \
            "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp" \
            && mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
        success "session-resume hook removed from settings.json"
    else
        skip "No UserPromptSubmit hook in settings.json"
    fi
else
    if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
        skip "settings.json not found"
    else
        warn "jq required to modify settings.json. Manually remove the session-resume hook."
    fi
fi

# ============================================================================
# 4. Optionally remove plugins
# WARNING: must run BEFORE section 5 (CLI uninstall) — needs claude command
# ============================================================================

echo ""
echo -n "  Also remove plugins installed by the setup? (y/N): "
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    info "Removing plugins..."

    if command_exists claude; then
        # Load plugin list from shared config file
        PLUGINS=()
        if [ -f "$PLUGINS_FILE" ]; then
            while IFS= read -r line || [ -n "$line" ]; do
                [ -z "$line" ] && continue
                [[ "$line" =~ ^# ]] && continue
                # Strip inline comments and trailing whitespace
                line="${line%%#*}"
                line="${line%"${line##*[![:space:]]}"}"
                [ -z "$line" ] && continue
                PLUGINS+=("$line")
            done < "$PLUGINS_FILE"
        else
            warn "plugins.txt not found ($PLUGINS_FILE). Use 'claude plugins list' to see installed plugins."
        fi
        for plugin in "${PLUGINS[@]}"; do
            claude plugins uninstall "$plugin" 2>/dev/null \
                && success "  $plugin removed" \
                || skip "  $plugin (not installed or error)"
        done

        # Remove marketplaces added by install
        info "Removing marketplaces..."
        MARKETPLACES=(
            "anthropics/claude-plugins-official"
            "obra/superpowers"
            "upstash/context7"
            "anthropics/claude-code"
        )
        for mp in "${MARKETPLACES[@]}"; do
            MP_NAME=$(echo "$mp" | cut -d'/' -f2)
            claude plugins marketplace remove "https://github.com/$mp" 2>/dev/null \
                && success "  $MP_NAME removed" \
                || skip "  $MP_NAME (not found or error)"
        done
    else
        warn "Claude CLI not available. Cannot uninstall plugins via CLI."
        for dir in "$CLAUDE_DIR/plugins" "$CLAUDE_DIR/installed-plugins"; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
                success "Directory removed: $dir"
            fi
        done
    fi
else
    skip "Plugins kept"
fi

# ============================================================================
# 5. Optionally uninstall Claude Code CLI
# ============================================================================

echo ""
echo -n "  Also uninstall Claude Code CLI? (y/N): "
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    info "Uninstalling CLI..."
    UNINSTALLED=false

    if command_exists npm && npm list -g @anthropic-ai/claude-code &>/dev/null; then
        npm uninstall -g @anthropic-ai/claude-code
        success "Claude Code uninstalled (npm)"
        UNINSTALLED=true
    fi

    if command_exists brew && brew list claude-code &>/dev/null; then
        brew uninstall claude-code
        success "Claude Code uninstalled (brew)"
        UNINSTALLED=true
    fi

    if command_exists dpkg && dpkg -s claude-code &>/dev/null 2>&1; then
        sudo apt-get remove -y claude-code 2>/dev/null || sudo dpkg -r claude-code 2>/dev/null
        success "Claude Code uninstalled (apt/dpkg)"
        UNINSTALLED=true
    fi

    if command_exists snap && snap list claude-code &>/dev/null 2>&1; then
        sudo snap remove claude-code
        success "Claude Code uninstalled (snap)"
        UNINSTALLED=true
    fi

    if command_exists claude; then
        CLAUDE_BIN=$(command -v claude 2>/dev/null)
        if [ -n "$CLAUDE_BIN" ]; then
            rm -f "$CLAUDE_BIN"
            success "Binary removed ($CLAUDE_BIN)"
            UNINSTALLED=true
        fi
    fi

    for p in "$HOME/.local/bin/claude" "$HOME/.claude/bin/claude" "/usr/local/bin/claude"; do
        if [ -f "$p" ]; then
            rm -f "$p"
            success "Binary removed ($p)"
            UNINSTALLED=true
        fi
    done

    if [ "$UNINSTALLED" = false ]; then
        warn "No Claude Code installation found."
    fi
else
    skip "Claude Code CLI kept"
fi

echo ""
success "Uninstall complete."
echo ""
