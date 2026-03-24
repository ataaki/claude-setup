#!/bin/bash
set -e

# ============================================================================
# Claude Code Setup - Automatic installation
# ============================================================================
# Installs Claude Code + config + plugins in a single command
# Usage: curl -fsSL https://raw.githubusercontent.com/yujacare/claude-setup/main/install.sh | bash
# Or:    git clone https://github.com/yujacare/claude-setup && cd claude-setup && ./install.sh
# ============================================================================

# In pipe mode (curl|bash), BASH_SOURCE is empty — use a non-existent path
# so ensure_config_dir detects the missing config/ and triggers a download
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="/nonexistent"
fi
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SCRIPTS_DIR="$CLAUDE_DIR/scripts"
CLEANUP_TEMP=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helpers
# ============================================================================

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
skip()    { echo -e "${YELLOW}[SKIP]${NC} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

# Detect if stdin is a terminal (interactive mode)
is_interactive() { [ -t 0 ]; }

# Ask user a yes/no question. Returns 0 (yes) or 1 (no).
# In non-interactive mode (curl|bash), returns the default silently.
# Usage: ask_user "question text" "y" or ask_user "question text" "n"
ask_user() {
    local question="$1"
    local default="$2"  # "y" or "n"

    if ! is_interactive; then
        if [ "$default" = "y" ]; then
            info "$question → oui (mode non-interactif)"
            return 0
        else
            info "$question → non (mode non-interactif)"
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
        if [[ "$REPLY" =~ ^[Nn]$ ]]; then
            return 1
        fi
        return 0
    else
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            return 0
        fi
        return 1
    fi
}

# Ensure config files are available (handles curl|bash mode)
ensure_config_dir() {
    if [ -d "$SCRIPT_DIR/config" ]; then
        return 0
    fi

    info "Config directory not found locally. Downloading repository..."
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)

    if command_exists git; then
        git clone --depth 1 https://github.com/yujacare/claude-setup.git "$TEMP_DIR/claude-setup" 2>/dev/null
        SCRIPT_DIR="$TEMP_DIR/claude-setup"
    elif command_exists curl; then
        curl -fsSL https://github.com/yujacare/claude-setup/archive/refs/heads/main.tar.gz | tar -xz -C "$TEMP_DIR"
        SCRIPT_DIR="$TEMP_DIR/claude-setup-main"
    else
        error "Cannot download config files. Use: git clone https://github.com/yujacare/claude-setup && cd claude-setup && ./install.sh"
    fi

    if [ ! -d "$SCRIPT_DIR/config" ]; then
        error "Failed to download config files."
    fi

    success "Config files downloaded to temp directory"
    CLEANUP_TEMP="$TEMP_DIR"
}

# Clean up temp directory on exit
cleanup() {
    if [ -n "$CLEANUP_TEMP" ] && [ -d "$CLEANUP_TEMP" ]; then
        rm -rf "$CLEANUP_TEMP"
    fi
}
trap cleanup EXIT

# ============================================================================
# Step 1: Install / Reinstall Claude Code
# ============================================================================

uninstall_claude_cli() {
    info "Desinstallation du CLI Claude Code..."
    local UNINSTALLED=false

    # npm (global package)
    if command_exists npm && npm list -g @anthropic-ai/claude-code &>/dev/null; then
        npm uninstall -g @anthropic-ai/claude-code
        success "Claude Code desinstalle (npm)"
        UNINSTALLED=true
    fi

    # Homebrew
    if command_exists brew && brew list claude-code &>/dev/null; then
        brew uninstall claude-code
        success "Claude Code desinstalle (brew)"
        UNINSTALLED=true
    fi

    # apt / dpkg (.deb package)
    if command_exists dpkg && dpkg -s claude-code &>/dev/null 2>&1; then
        sudo apt-get remove -y claude-code 2>/dev/null || sudo dpkg -r claude-code 2>/dev/null
        success "Claude Code desinstalle (apt/dpkg)"
        UNINSTALLED=true
    fi

    # snap
    if command_exists snap && snap list claude-code &>/dev/null 2>&1; then
        sudo snap remove claude-code
        success "Claude Code desinstalle (snap)"
        UNINSTALLED=true
    fi

    # winget (WSL2 can access Windows winget via .exe suffix)
    if command_exists winget.exe && winget.exe list --id "Anthropic.Claude" &>/dev/null 2>&1; then
        winget.exe uninstall --id "Anthropic.Claude" --silent 2>/dev/null
        success "Claude Code desinstalle (winget)"
        UNINSTALLED=true
    fi

    # Fallback: remove binary found in PATH
    if command_exists claude; then
        local CLAUDE_BIN
        CLAUDE_BIN=$(command -v claude 2>/dev/null)
        if [ -n "$CLAUDE_BIN" ]; then
            rm -f "$CLAUDE_BIN"
            success "Binaire supprime ($CLAUDE_BIN)"
            UNINSTALLED=true
        fi
    fi

    # Clean up known binary locations even if command is gone
    local KNOWN_PATHS=(
        "$HOME/.local/bin/claude"
        "$HOME/.claude/bin/claude"
        "/usr/local/bin/claude"
    )
    for p in "${KNOWN_PATHS[@]}"; do
        if [ -f "$p" ]; then
            rm -f "$p"
            success "Binaire supprime ($p)"
            UNINSTALLED=true
        fi
    done

    if [ "$UNINSTALLED" = false ]; then
        warn "Aucune installation de Claude Code trouvee."
        return 1
    fi

    return 0
}

uninstall_claude_config() {
    info "Suppression de la config (~/.claude/)..."

    if [ -d "$CLAUDE_DIR" ]; then
        # Backup before deleting
        local BACKUP="$HOME/.claude-backup-$(date +%Y%m%d%H%M%S)"
        cp -r "$CLAUDE_DIR" "$BACKUP"
        success "Backup cree: $BACKUP"

        rm -rf "$CLAUDE_DIR"
        success "Config supprimee (~/.claude/)"
    else
        skip "Aucune config trouvee (~/.claude/ n'existe pas)"
    fi
}

uninstall_claude_plugins() {
    info "Suppression des plugins..."

    # Prefer CLI if available (proper uninstall)
    if command_exists claude; then
        local PLUGIN_LIST
        PLUGIN_LIST=$(claude plugins list 2>/dev/null || echo "")
        if [ -n "$PLUGIN_LIST" ]; then
            echo "$PLUGIN_LIST" | while IFS= read -r plugin; do
                [ -z "$plugin" ] && continue
                claude plugins uninstall "$plugin" 2>/dev/null \
                    && success "  Plugin supprime: $plugin" \
                    || skip "  Plugin non supprime: $plugin"
            done
            return 0
        fi
    fi

    # Fallback: remove known plugin directories
    local FOUND=false
    for dir in "$CLAUDE_DIR/plugins" "$CLAUDE_DIR/installed-plugins"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            success "Repertoire supprime: $dir"
            FOUND=true
        fi
    done

    if [ "$FOUND" = false ]; then
        skip "Aucun plugin trouve"
    fi
}

uninstall_claude() {
    # Collect all decisions upfront before taking any action
    local DO_CONFIG=false
    local DO_PLUGINS=false

    echo ""
    if ask_user "Supprimer aussi la config (~/.claude/) ?" "n"; then
        DO_CONFIG=true
    else
        if ask_user "Supprimer les plugins ?" "n"; then
            DO_PLUGINS=true
        fi
    fi

    # Order matters: plugins first (needs CLI), then CLI, then config
    if [ "$DO_PLUGINS" = true ]; then
        uninstall_claude_plugins
    fi

    # || true: prevent set -e from killing the script if no install is found
    uninstall_claude_cli || true

    if [ "$DO_CONFIG" = true ]; then
        uninstall_claude_config
    fi
}

install_claude() {
    echo ""
    echo "============================================"
    echo "  Step 1: Claude Code CLI"
    echo "============================================"

    info "Installation de Claude Code..."

    # Attempt 1: Native installer (no Node.js needed)
    if install_claude_native; then
        return 0
    fi

    warn "Installation native echouee. Fallback vers npm..."

    # Attempt 2: Via npm (needs Node.js)
    if ! command_exists node; then
        info "Node.js non trouve. Installation de Node.js..."
        install_node
    fi

    if command_exists npm; then
        info "Installation de Claude Code via npm..."
        npm install -g @anthropic-ai/claude-code
        if command_exists claude; then
            success "Claude Code installe via npm"
            return 0
        fi
    fi

    error "Impossible d'installer Claude Code. Installez-le manuellement: https://docs.anthropic.com/en/docs/claude-code/getting-started"
}

install_claude_native() {
    local OS
    OS="$(uname -s)"

    case "$OS" in
        Darwin)
            # macOS: try brew first
            if command_exists brew; then
                info "Tentative: brew install claude-code..."
                if brew install claude-code 2>/dev/null; then
                    if command_exists claude; then
                        success "Claude Code installe via Homebrew"
                        return 0
                    fi
                fi
            fi
            # macOS: try the official installer script
            info "Tentative: installeur officiel macOS..."
            if curl -fsSL https://cli.anthropic.com/install.sh | sh 2>/dev/null; then
                export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
                if command_exists claude; then
                    success "Claude Code installe via installeur officiel"
                    return 0
                fi
            fi
            ;;
        Linux)
            # Linux: try the official installer script
            info "Tentative: installeur officiel Linux..."
            if curl -fsSL https://cli.anthropic.com/install.sh | sh 2>/dev/null; then
                export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
                if command_exists claude; then
                    success "Claude Code installe via installeur officiel"
                    return 0
                fi
            fi
            ;;
    esac

    return 1
}

install_node() {
    # Attempt 1: Already installed
    if command_exists node; then
        success "Node.js deja installe ($(node --version))"
        return 0
    fi

    # Attempt 2: Homebrew (macOS/Linux)
    if command_exists brew; then
        info "Installation de Node.js via Homebrew..."
        brew install node
        if command_exists node; then
            success "Node.js installe via Homebrew ($(node --version))"
            return 0
        fi
    fi

    # Attempt 3: nvm
    info "Installation de Node.js via nvm..."
    if curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>/dev/null; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm install --lts
        if command_exists node; then
            success "Node.js installe via nvm ($(node --version))"
            return 0
        fi
    fi

    error "Impossible d'installer Node.js. Installez-le manuellement: https://nodejs.org/"
}

# ============================================================================
# Step 2: Setup config directory
# ============================================================================

setup_config() {
    echo ""
    echo "============================================"
    echo "  Step 2: Configuration"
    echo "============================================"

    # Ensure directories exist
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_SCRIPTS_DIR"

    # --- CLAUDE.md ---
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        if ask_user "~/.claude/CLAUDE.md existe deja. Remplacer ?" "n"; then
            # Backup before overwriting
            cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
            cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
            success "CLAUDE.md remplace (backup cree)"
        else
            skip "CLAUDE.md conserve"
        fi
    else
        cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
        success "CLAUDE.md installe"
    fi

    # --- session-resume.sh ---
    cp "$SCRIPT_DIR/config/scripts/session-resume.sh" "$CLAUDE_SCRIPTS_DIR/session-resume.sh"
    chmod +x "$CLAUDE_SCRIPTS_DIR/session-resume.sh"
    success "session-resume.sh installe"

    # --- settings.json (merge) ---
    merge_settings
}

merge_settings() {
    local EXISTING="$CLAUDE_DIR/settings.json"
    local NEW="$SCRIPT_DIR/config/settings.json"

    if ! command_exists jq; then
        info "Installation de jq pour merger les settings..."
        if command_exists brew; then
            brew install jq
        elif command_exists apt-get; then
            sudo apt-get install -y jq
        else
            warn "jq non disponible. Copie directe des settings (backup cree)."
            if [ -f "$EXISTING" ]; then
                cp "$EXISTING" "$EXISTING.backup.$(date +%Y%m%d%H%M%S)"
                warn "Backup: $EXISTING.backup.*"
            fi
            cp "$NEW" "$EXISTING"
            success "settings.json installe (copie directe)"
            return 0
        fi
    fi

    if [ -f "$EXISTING" ]; then
        # Backup
        cp "$EXISTING" "$EXISTING.backup.$(date +%Y%m%d%H%M%S)"

        # Merge hooks: add session-resume hook if not already present
        local HAS_RESUME
        HAS_RESUME=$(jq '.hooks.UserPromptSubmit[0].hooks // [] | map(select(.command | contains("session-resume"))) | length' "$EXISTING" 2>/dev/null || echo "0")

        if [ "$HAS_RESUME" -gt 0 ]; then
            skip "Hook session-resume deja present dans settings.json"
        else
            # Add the session-resume hook to UserPromptSubmit
            local RESUME_HOOK='{"type":"command","command":"$HOME/.claude/scripts/session-resume.sh"}'

            if jq '.hooks.UserPromptSubmit' "$EXISTING" 2>/dev/null | grep -q "null"; then
                # No UserPromptSubmit exists, create it
                jq --argjson hook "$RESUME_HOOK" \
                    '.hooks.UserPromptSubmit = [{"hooks": [$hook]}]' \
                    "$EXISTING" > "$EXISTING.tmp" && mv "$EXISTING.tmp" "$EXISTING"
            else
                # UserPromptSubmit exists, add hook to first entry
                jq --argjson hook "$RESUME_HOOK" \
                    '.hooks.UserPromptSubmit[0].hooks += [$hook]' \
                    "$EXISTING" > "$EXISTING.tmp" && mv "$EXISTING.tmp" "$EXISTING"
            fi
            success "Hook session-resume ajoute a settings.json"
        fi
    else
        cp "$NEW" "$EXISTING"
        success "settings.json cree"
    fi
}

# ============================================================================
# Step 3: Install plugins
# ============================================================================

install_plugins() {
    echo ""
    echo "============================================"
    echo "  Step 3: Marketplaces & Plugins"
    echo "============================================"

    # --- Marketplaces ---
    local MARKETPLACES=(
        "anthropics/claude-plugins-official"
        "obra/superpowers"
        "upstash/context7"
        "anthropics/claude-code"
    )

    for mp in "${MARKETPLACES[@]}"; do
        local MP_NAME
        MP_NAME=$(echo "$mp" | cut -d'/' -f2)
        info "Marketplace: $mp"
        claude plugins marketplace add "https://github.com/$mp" 2>/dev/null && success "  $MP_NAME ajoute" || skip "  $MP_NAME deja present"
    done

    # --- Plugins (loaded from shared config/plugins.txt) ---
    local PLUGINS=()
    local PLUGINS_FILE="$SCRIPT_DIR/config/plugins.txt"
    if [ ! -f "$PLUGINS_FILE" ]; then
        warn "plugins.txt not found at $PLUGINS_FILE — skipping plugin install"
        return 0
    fi
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue
        PLUGINS+=("$line")
    done < "$PLUGINS_FILE"

    echo ""
    info "Installation de ${#PLUGINS[@]} plugins..."
    echo ""

    local INSTALLED=0
    local SKIPPED=0

    for plugin in "${PLUGINS[@]}"; do
        if claude plugins install "$plugin" 2>/dev/null; then
            success "  $plugin"
            INSTALLED=$((INSTALLED + 1))
        else
            skip "  $plugin (deja installe ou indisponible)"
            SKIPPED=$((SKIPPED + 1))
        fi
    done

    echo ""
    success "Plugins: $INSTALLED installes, $SKIPPED deja presents"
}

# ============================================================================
# Step 4: Summary
# ============================================================================

summary() {
    echo ""
    echo "============================================"
    echo -e "  ${GREEN}Installation terminee !${NC}"
    echo "============================================"
    echo ""
    echo "  Ce qui a ete installe :"
    echo "  - Claude Code CLI"
    echo "  - CLAUDE.md global (workflow, securite, TDD, etc.)"
    echo "  - Hook session-resume (reprise apres coupure)"
    echo "  - Plugins (superpowers, frontend-design, security, etc.)"
    echo ""
    echo "  Pour commencer :"
    echo "    claude"
    echo ""
    echo "  Pour verifier l'installation :"
    echo "    claude --version"
    echo "    claude plugins list"
    echo ""
    echo "  Documentation du framework :"
    echo "    cat ~/.claude/CLAUDE.md"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "============================================"
    echo "  Claude Code Setup"
    echo "  github.com/yujacare/claude-setup"
    echo "============================================"

    # Ensure config files are available (handles curl|bash mode)
    ensure_config_dir

    if command_exists claude; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
        warn "Claude Code est deja installe ($CLAUDE_VERSION)"
        echo ""
        if ask_user "Desinstaller et reinstaller Claude Code ?" "n"; then
            uninstall_claude
            install_claude
        else
            skip "Reinstallation de Claude Code ignoree"
            if ! ask_user "Installer quand meme la config et les plugins ?" "y"; then
                info "Installation annulee."
                exit 0
            fi
        fi
    else
        install_claude
    fi

    setup_config
    install_plugins
    summary
}

main "$@"
