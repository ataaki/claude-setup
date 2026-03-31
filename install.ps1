#Requires -Version 5.1
# ============================================================================
# Claude Code Setup - Automatic installation (PowerShell)
# ============================================================================
# Installs Claude Code + config + plugins in a single command
# Usage: git clone https://github.com/ataaki/claude-setup && cd claude-setup && .\install.ps1
# Or:    irm https://raw.githubusercontent.com/ataaki/claude-setup/main/install.ps1 | iex
# ============================================================================

$ErrorActionPreference = 'Stop'

# Detect pipe mode (irm|iex) — $PSScriptRoot is empty when piped
if ($PSScriptRoot) {
    $ScriptDir = $PSScriptRoot
} else {
    $ScriptDir = $null
}

$ClaudeDir = Join-Path $HOME ".claude"
$ClaudeScriptsDir = Join-Path $ClaudeDir "scripts"
$CleanupTemp = $null

# ============================================================================
# Helpers
# ============================================================================

function Write-Info    { param([string]$Msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $Msg }
function Write-Success { param([string]$Msg) Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $Msg }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Skip    { param([string]$Msg) Write-Host "[SKIP] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }

function Write-Fatal {
    param([string]$Msg)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Msg
    throw $Msg
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-Interactive {
    return [Environment]::UserInteractive -and ($null -ne $ScriptDir)
}

function Read-YesNo {
    param(
        [string]$Question,
        [string]$Default = "n"  # "y" or "n"
    )

    if (-not (Test-Interactive)) {
        if ($Default -eq "y") {
            Write-Info "$Question -> yes (non-interactive mode)"
            return $true
        } else {
            Write-Info "$Question -> no (non-interactive mode)"
            return $false
        }
    }

    if ($Default -eq "y") {
        $prompt = "  $Question (Y/n): "
    } else {
        $prompt = "  $Question (y/N): "
    }

    Write-Host $prompt -NoNewline
    $reply = Read-Host

    if ($Default -eq "y") {
        return $reply -notmatch '^[Nn]$'
    } else {
        return $reply -match '^[Yy]$'
    }
}

function Ensure-ConfigDir {
    if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "config"))) {
        return
    }

    Write-Info "Config directory not found locally. Downloading repository..."
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "claude-setup-$(Get-Random)"
    $script:CleanupTemp = $tempDir

    if (Test-Command git) {
        & git clone --depth 1 https://github.com/ataaki/claude-setup.git $tempDir 2>$null
        $script:ScriptDir = $tempDir
    } else {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $archive = Join-Path $tempDir "repo.zip"
        Invoke-WebRequest -Uri "https://github.com/ataaki/claude-setup/archive/refs/heads/main.zip" -OutFile $archive -UseBasicParsing
        Expand-Archive -Path $archive -DestinationPath $tempDir -Force
        $script:ScriptDir = Join-Path $tempDir "claude-setup-main"
    } else {
        Write-Fatal "Cannot download config files. Use: git clone https://github.com/ataaki/claude-setup && cd claude-setup && .\install.ps1"
    }

    if (-not (Test-Path (Join-Path $script:ScriptDir "config"))) {
        Write-Fatal "Failed to download config files."
    }

    Write-Success "Config files downloaded to temp directory"
}

# ============================================================================
# Step 1: Install / Reinstall Claude Code
# ============================================================================

function Uninstall-ClaudeCli {
    Write-Info "Uninstalling Claude Code CLI..."
    $uninstalled = $false

    # npm
    if ((Test-Command npm) -and (& npm list -g @anthropic-ai/claude-code 2>$null)) {
        & npm uninstall -g @anthropic-ai/claude-code
        Write-Success "Claude Code uninstalled (npm)"
        $uninstalled = $true
    }

    # winget
    if (Test-Command winget) {
        & winget list --id "Anthropic.Claude" *>$null
        if ($LASTEXITCODE -eq 0) {
            & winget uninstall --id "Anthropic.Claude" --silent 2>&1 | Out-Null
            Write-Success "Claude Code uninstalled (winget)"
            $uninstalled = $true
        }
    }

    # Scoop
    if (Test-Command scoop) {
        $scoopList = & scoop list claude-code 2>$null
        if ($LASTEXITCODE -eq 0) {
            & scoop uninstall claude-code
            Write-Success "Claude Code uninstalled (scoop)"
            $uninstalled = $true
        }
    }

    # Chocolatey
    if (Test-Command choco) {
        $chocoList = & choco list --local-only claude-code 2>$null
        if ($chocoList -match "claude-code") {
            & choco uninstall claude-code -y
            Write-Success "Claude Code uninstalled (choco)"
            $uninstalled = $true
        }
    }

    # Fallback: remove binary found in PATH
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        $claudeBin = $claudeCmd.Source
        if ($claudeBin -and (Test-Path $claudeBin)) {
            Remove-Item $claudeBin -Force
            Write-Success "Binary removed ($claudeBin)"
            $uninstalled = $true
        }
    }

    # Clean up known locations
    $knownPaths = @(
        (Join-Path $HOME ".local/bin/claude.exe"),
        (Join-Path $HOME ".local/bin/claude"),
        (Join-Path $HOME ".claude/bin/claude.exe"),
        (Join-Path $HOME ".claude/bin/claude"),
        (Join-Path $env:LOCALAPPDATA "Programs/claude/claude.exe")
    )
    # Also search winget package directories for claude binaries
    $wingetPkgDir = Join-Path $env:LOCALAPPDATA "Microsoft/WinGet/Packages"
    if (Test-Path $wingetPkgDir) {
        Get-ChildItem -Path $wingetPkgDir -Filter "claude.exe" -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { $knownPaths += $_.FullName }
    }
    foreach ($p in $knownPaths) {
        if (Test-Path $p) {
            Remove-Item $p -Force
            Write-Success "Binary removed ($p)"
            $uninstalled = $true
        }
    }

    if (-not $uninstalled) {
        Write-Warn "No Claude Code installation found."
        return $false
    }
    return $true
}

function Uninstall-ClaudeConfig {
    Write-Info "Removing config (~/.claude/)..."
    if (Test-Path $ClaudeDir) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = Join-Path $HOME ".claude-backup-$timestamp"
        Copy-Item -Path $ClaudeDir -Destination $backup -Recurse
        Write-Success "Backup created: $backup"

        Remove-Item -Path $ClaudeDir -Recurse -Force
        Write-Success "Config removed (~/.claude/)"
    } else {
        Write-Skip "No config found (~/.claude/ does not exist)"
    }
}

function Uninstall-ClaudePlugins {
    Write-Info "Removing plugins..."

    if (Test-Command claude) {
        $pluginList = & claude plugins list 2>$null
        if ($pluginList) {
            foreach ($plugin in $pluginList) {
                if (-not $plugin) { continue }
                try {
                    & claude plugins uninstall $plugin 2>$null
                    Write-Success "  Plugin removed: $plugin"
                } catch {
                    Write-Skip "  Plugin not removed: $plugin"
                }
            }
            return
        }
    }

    # Fallback: remove known plugin directories
    $found = $false
    foreach ($dir in @((Join-Path $ClaudeDir "plugins"), (Join-Path $ClaudeDir "installed-plugins"))) {
        if (Test-Path $dir) {
            Remove-Item $dir -Recurse -Force
            Write-Success "Directory removed: $dir"
            $found = $true
        }
    }

    if (-not $found) {
        Write-Skip "No plugins found"
    }
}

function Uninstall-Claude {
    $doConfig = $false
    $doPlugins = $false

    Write-Host ""
    if (Read-YesNo "Also remove config (~/.claude/)?" "n") {
        $doConfig = $true
    } else {
        if (Read-YesNo "Remove plugins?" "n") {
            $doPlugins = $true
        }
    }

    # Order: plugins first (needs CLI), then CLI, then config
    if ($doPlugins) { Uninstall-ClaudePlugins }
    Uninstall-ClaudeCli | Out-Null
    if ($doConfig) { Uninstall-ClaudeConfig }
}

function Install-ClaudeNative {
    # Windows: try official installer first
    Write-Info "Trying: official Windows installer..."
    try {
        Invoke-RestMethod -Uri "https://claude.ai/install.ps1" | Invoke-Expression
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Command claude) {
            Write-Success "Claude Code installed via official installer"
            return $true
        }
    } catch {
        # Installer not available or failed
    }

    # Fallback to winget
    if (Test-Command winget) {
        Write-Info "Trying: winget install Anthropic.Claude..."
        & winget install --id "Anthropic.Claude" --accept-source-agreements --accept-package-agreements *>$null
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Command claude) {
            Write-Success "Claude Code installed via winget"
            return $true
        }
    }

    return $false
}

function Install-Node {
    if (Test-Command node) {
        $nodeVersion = & node --version
        Write-Success "Node.js already installed ($nodeVersion)"
        return
    }

    # Attempt 1: winget
    if (Test-Command winget) {
        Write-Info "Installing Node.js via winget..."
        & winget install --id "OpenJS.NodeJS.LTS" --accept-source-agreements --accept-package-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Command node) {
            $nodeVersion = & node --version
            Write-Success "Node.js installed via winget ($nodeVersion)"
            return
        }
    }

    # Attempt 2: Chocolatey
    if (Test-Command choco) {
        Write-Info "Installing Node.js via Chocolatey..."
        & choco install nodejs-lts -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Command node) {
            $nodeVersion = & node --version
            Write-Success "Node.js installed via Chocolatey ($nodeVersion)"
            return
        }
    }

    Write-Fatal "Cannot install Node.js. Install manually: https://nodejs.org/"
}

function Install-Claude {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Step 1: Claude Code CLI"
    Write-Host "============================================"

    Write-Info "Installing Claude Code..."

    # Attempt 1: Native installer
    if (Install-ClaudeNative) {
        return
    }

    Write-Warn "Native installation failed. Falling back to npm..."

    # Attempt 2: Via npm (needs Node.js)
    if (-not (Test-Command node)) {
        Write-Info "Node.js not found. Installing Node.js..."
        Install-Node
    }

    if (Test-Command npm) {
        Write-Info "Installing Claude Code via npm..."
        & npm install -g @anthropic-ai/claude-code
        if (Test-Command claude) {
            Write-Success "Claude Code installed via npm"
            return
        }
    }

    Write-Fatal "Cannot install Claude Code. Install manually: https://docs.anthropic.com/en/docs/claude-code/getting-started"
}

# ============================================================================
# Step 2: Setup config directory
# ============================================================================

function Merge-Settings {
    $existing = Join-Path $ClaudeDir "settings.json"
    $new = Join-Path $ScriptDir "config/settings.json"

    if (Test-Path $existing) {
        # Backup
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        Copy-Item $existing "$existing.backup.$timestamp"

        try {
            $settings = Get-Content $existing -Raw | ConvertFrom-Json

            # Check if session-resume hook already present
            $hasResume = $false
            if ($settings.hooks -and $settings.hooks.UserPromptSubmit) {
                foreach ($entry in $settings.hooks.UserPromptSubmit) {
                    if ($entry.hooks) {
                        foreach ($hook in $entry.hooks) {
                            if ($hook.command -and $hook.command -match "session-resume") {
                                $hasResume = $true
                                break
                            }
                        }
                    }
                    if ($hasResume) { break }
                }
            }

            if ($hasResume) {
                Write-Skip "session-resume hook already present in settings.json"
            } else {
                $resumeHook = [PSCustomObject]@{
                    type    = "command"
                    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/session-resume.ps1"'
                }

                # Build or append to hooks structure
                if (-not $settings.hooks) {
                    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{})
                }
                if (-not $settings.hooks.UserPromptSubmit) {
                    $settings.hooks | Add-Member -NotePropertyName "UserPromptSubmit" -NotePropertyValue @(
                        [PSCustomObject]@{ hooks = @($resumeHook) }
                    )
                } else {
                    $firstEntry = $settings.hooks.UserPromptSubmit[0]
                    if (-not $firstEntry.hooks) {
                        $firstEntry | Add-Member -NotePropertyName "hooks" -NotePropertyValue @($resumeHook)
                    } else {
                        $firstEntry.hooks = @($firstEntry.hooks) + $resumeHook
                    }
                }

                $settings | ConvertTo-Json -Depth 10 | Set-Content $existing -Encoding UTF8
                Write-Success "session-resume hook added to settings.json"
            }
        } catch {
            Write-Warn "settings.json is malformed. Direct copy (backup created)."
            Copy-Item $new $existing -Force
            Write-Success "settings.json installed (direct copy)"
        }
    } else {
        # No existing settings — create from template but use PowerShell hook command
        $newSettings = Get-Content $new -Raw | ConvertFrom-Json
        # Replace the bash command with PowerShell equivalent
        if ($newSettings.hooks.UserPromptSubmit[0].hooks[0].command) {
            $newSettings.hooks.UserPromptSubmit[0].hooks[0].command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/session-resume.ps1"'
        }
        $newSettings | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $ClaudeDir "settings.json") -Encoding UTF8
        Write-Success "settings.json created"
    }
}

function Setup-Config {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Step 2: Configuration"
    Write-Host "============================================"

    # Ensure directories exist
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ClaudeScriptsDir -Force | Out-Null

    # --- CLAUDE.md ---
    $claudeMdDest = Join-Path $ClaudeDir "CLAUDE.md"
    $claudeMdSrc = Join-Path $ScriptDir "config/CLAUDE.md"

    if (Test-Path $claudeMdDest) {
        if (Read-YesNo "~/.claude/CLAUDE.md already exists. Replace?" "n") {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            Copy-Item $claudeMdDest "$claudeMdDest.backup.$timestamp"
            Copy-Item $claudeMdSrc $claudeMdDest -Force
            Write-Success "CLAUDE.md replaced (backup created)"
        } else {
            Write-Skip "CLAUDE.md kept"
        }
    } else {
        Copy-Item $claudeMdSrc $claudeMdDest
        Write-Success "CLAUDE.md installed"
    }

    # --- session-resume.ps1 ---
    Copy-Item (Join-Path $ScriptDir "config/scripts/session-resume.ps1") (Join-Path $ClaudeScriptsDir "session-resume.ps1") -Force
    Write-Success "session-resume.ps1 installed"

    # Also install the bash version for WSL/Git Bash compatibility
    $bashScript = Join-Path $ScriptDir "config/scripts/session-resume.sh"
    if (Test-Path $bashScript) {
        Copy-Item $bashScript (Join-Path $ClaudeScriptsDir "session-resume.sh") -Force
        Write-Success "session-resume.sh installed (WSL/Git Bash compatibility)"
    }

    # --- settings.json (merge) ---
    Merge-Settings
}

# ============================================================================
# Step 3: Install plugins
# ============================================================================

function Install-Plugins {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Step 3: Marketplaces & Plugins"
    Write-Host "============================================"

    # --- Marketplaces ---
    $marketplaces = @(
        "anthropics/claude-plugins-official",
        "obra/superpowers",
        "upstash/context7",
        "anthropics/claude-code"
    )

    foreach ($mp in $marketplaces) {
        $mpName = ($mp -split '/')[-1]
        Write-Info "Marketplace: $mp"
        try {
            & claude plugins marketplace add "https://github.com/$mp" 2>$null
            Write-Success "  $mpName added"
        } catch {
            Write-Skip "  $mpName already present"
        }
    }

    # --- Plugins (loaded from config/plugins.txt) ---
    $pluginsFile = Join-Path $ScriptDir "config/plugins.txt"
    if (-not (Test-Path $pluginsFile)) {
        Write-Warn "plugins.txt not found at $pluginsFile - skipping plugin install"
        return
    }

    $plugins = @(Get-Content $pluginsFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            # Strip inline comments
            ($line -split '#')[0].Trim()
        }
    } | Where-Object { $_ })

    Write-Host ""
    Write-Info "Installing $($plugins.Count) plugins..."
    Write-Host ""

    $installed = 0
    $skipped = 0

    foreach ($plugin in $plugins) {
        try {
            & claude plugins install $plugin 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  $plugin"
                $installed++
            } else {
                Write-Skip "  $plugin (already installed or unavailable)"
                $skipped++
            }
        } catch {
            Write-Skip "  $plugin (already installed or unavailable)"
            $skipped++
        }
    }

    Write-Host ""
    Write-Success "Plugins: $installed installed, $skipped already present"
}

# ============================================================================
# Step 4: Summary
# ============================================================================

function Show-Summary {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "============================================"
    Write-Host ""
    Write-Host "  What was installed:"
    Write-Host "  - Claude Code CLI"
    Write-Host "  - Global CLAUDE.md (workflow, security, TDD, etc.)"
    Write-Host "  - session-resume hook (resume after interruption)"
    Write-Host "  - Plugins (superpowers, frontend-design, security, etc.)"
    Write-Host ""
    Write-Host "  To start:"
    Write-Host "    claude"
    Write-Host ""
    Write-Host "  To verify the installation:"
    Write-Host "    claude --version"
    Write-Host "    claude plugins list"
    Write-Host ""
    Write-Host "  Framework documentation:"
    Write-Host "    Get-Content ~/.claude/CLAUDE.md"
    Write-Host ""
}

# ============================================================================
# Main
# ============================================================================

try {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Claude Code Setup (PowerShell)"
    Write-Host "  github.com/ataaki/claude-setup"
    Write-Host "============================================"

    # Ensure config files are available (handles irm|iex mode)
    Ensure-ConfigDir

    if (Test-Command claude) {
        $claudeVersion = try { & claude --version 2>$null } catch { "unknown" }
        Write-Warn "Claude Code is already installed ($claudeVersion)"
        Write-Host ""
        if (Read-YesNo "Uninstall and reinstall Claude Code?" "n") {
            Uninstall-Claude
            Install-Claude
        } else {
            Write-Skip "Claude Code reinstall skipped"
            if (-not (Read-YesNo "Install config and plugins anyway?" "y")) {
                Write-Info "Installation cancelled."
                return
            }
        }
    } else {
        Install-Claude
    }

    Setup-Config
    Install-Plugins
    Show-Summary
} finally {
    # Cleanup temp directory
    if ($CleanupTemp -and (Test-Path $CleanupTemp)) {
        Remove-Item $CleanupTemp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
