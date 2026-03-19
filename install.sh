#!/bin/bash
set -e

# ============================================================================
# Claude Code Setup - Installation automatique
# ============================================================================
# Installe Claude Code + config + plugins en une seule commande
# Usage: curl -fsSL https://raw.githubusercontent.com/yujacare/claude-setup/main/install.sh | bash
# Ou:    git clone https://github.com/yujacare/claude-setup && cd claude-setup && ./install.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SCRIPTS_DIR="$CLAUDE_DIR/scripts"

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

# ============================================================================
# Step 1: Install Claude Code
# ============================================================================

install_claude() {
    echo ""
    echo "============================================"
    echo "  Step 1: Claude Code CLI"
    echo "============================================"

    if command_exists claude; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
        success "Claude Code deja installe ($CLAUDE_VERSION)"
        return 0
    fi

    info "Claude Code non trouve. Tentative d'installation native..."

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
                # Reload PATH
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
        warn "~/.claude/CLAUDE.md existe deja."
        echo -n "  Remplacer ? (y/N): "
        read -r REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
            success "CLAUDE.md remplace"
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

    # --- Plugins ---
    local PLUGINS=(
        "superpowers@claude-plugins-official"
        "superpowers@superpowers-dev"
        "frontend-design@claude-plugins-official"
        "frontend-design@claude-code-plugins"
        "security-guidance@claude-plugins-official"
        "security-guidance@claude-code-plugins"
        "context7@claude-plugins-official"
        "context7-plugin@context7-marketplace"
        "code-simplifier@claude-plugins-official"
        "playwright@claude-plugins-official"
        "typescript-lsp@claude-plugins-official"
        "pyright-lsp@claude-plugins-official"
        "explanatory-output-style@claude-plugins-official"
        "learning-output-style@claude-plugins-official"
        "greptile@claude-plugins-official"
        "ralph-loop@claude-plugins-official"
        "claude-md-management@claude-plugins-official"
    )

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
    echo "  - 17 plugins (superpowers, frontend-design, security, etc.)"
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

    install_claude
    setup_config
    install_plugins
    summary
}

main "$@"
