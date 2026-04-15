#!/bin/bash
set -e

# ============================================================================
# Claude Code Setup - Uninstall
# ============================================================================
# Reverts changes made by install.sh
# Can optionally uninstall Claude Code CLI, plugins, and config
# ============================================================================

# In pipe mode (curl|bash), BASH_SOURCE is empty — use a non-existent path
# so ensure_config_dir detects the missing config/ and triggers a download
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="/nonexistent"
fi
CLAUDE_DIR="$HOME/.claude"
CLEANUP_TEMP=""

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

# Detect if stdin is a terminal (interactive mode)
is_interactive() { [ -t 0 ]; }

# Ask user a yes/no question. In non-interactive mode, returns the default.
ask_user() {
    local question="$1"
    local default="$2"  # "y" or "n"

    if ! is_interactive; then
        if [ "$default" = "y" ]; then
            info "$question → yes (non-interactive mode)"
            return 0
        else
            info "$question → no (non-interactive mode)"
            return 1
        fi
    fi

    if [ "$default" = "y" ]; then
        echo -n "  $question (Y/n): "
    else
        echo -n "  $question (y/N): "
    fi

    read -r REPLY || REPLY=""

    if [ "$default" = "y" ]; then
        [[ "$REPLY" =~ ^[Nn]$ ]] && return 1
        return 0
    else
        [[ "$REPLY" =~ ^[Yy]$ ]] && return 0
        return 1
    fi
}

# Ensure config files are available (handles curl|bash mode)
ensure_config_dir() {
    if [ -d "$SCRIPT_DIR/config" ]; then
        return 0
    fi

    info "Pipe mode detected. Downloading claude-setup repository for config files..."
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    CLEANUP_TEMP="$TEMP_DIR"

    if command_exists git; then
        git clone --depth 1 https://github.com/ataaki/claude-setup.git "$TEMP_DIR/claude-setup" 2>/dev/null
        SCRIPT_DIR="$TEMP_DIR/claude-setup"
    elif command_exists curl; then
        curl -fsSL https://github.com/ataaki/claude-setup/archive/refs/heads/main.tar.gz | tar -xz -C "$TEMP_DIR"
        SCRIPT_DIR="$TEMP_DIR/claude-setup-main"
    else
        warn "Cannot download config files. Plugin removal will be skipped."
        return 1
    fi

    if [ ! -d "$SCRIPT_DIR/config" ]; then
        warn "Failed to download config files. Plugin removal will be skipped."
        return 1
    fi

    success "Config files downloaded to temp directory"
}

# Cleanup temp directory on exit
cleanup() {
    if [ -n "$CLEANUP_TEMP" ] && [ -d "$CLEANUP_TEMP" ]; then
        rm -rf "$CLEANUP_TEMP"
    fi
}
trap cleanup EXIT

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
if ! ask_user "Continue?" "n"; then
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
        if ask_user "Restore backup ($LATEST_BACKUP)?" "n"; then
            cp "$LATEST_BACKUP" "$CLAUDE_DIR/CLAUDE.md"
            success "Backup restored"
        fi  # end ask_user restore
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
if ask_user "Also remove plugins installed by the setup?" "n"; then
    info "Removing plugins..."

    if command_exists claude; then
        # Ensure config dir is available (downloads repo in pipe mode)
        ensure_config_dir
        PLUGINS_FILE="$SCRIPT_DIR/config/plugins.txt"

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
        MARKETPLACES_FILE="$SCRIPT_DIR/config/marketplaces.txt"
        MARKETPLACES=()
        if [ -f "$MARKETPLACES_FILE" ]; then
            while IFS= read -r line || [ -n "$line" ]; do
                [ -z "$line" ] && continue
                [[ "$line" =~ ^# ]] && continue
                line="${line%%#*}"
                line="${line%"${line##*[![:space:]]}"}"
                [ -z "$line" ] && continue
                MARKETPLACES+=("$line")
            done < "$MARKETPLACES_FILE"
        else
            warn "marketplaces.txt not found ($MARKETPLACES_FILE). Skipping marketplace removal."
        fi
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
if ask_user "Also uninstall Claude Code CLI?" "n"; then
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
