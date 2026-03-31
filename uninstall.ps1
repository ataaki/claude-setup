#Requires -Version 5.1
# ============================================================================
# Claude Code Setup - Uninstall (PowerShell)
# ============================================================================
# Reverts changes made by install.ps1
# Can optionally uninstall Claude Code CLI, plugins, and config
# ============================================================================

$ErrorActionPreference = 'Stop'

# Detect pipe mode (irm|iex) — $PSScriptRoot is empty when piped
if ($PSScriptRoot) {
    $ScriptDir = $PSScriptRoot
} else {
    $ScriptDir = $null
}

$ClaudeDir = Join-Path $HOME ".claude"
$CleanupTemp = $null

# ============================================================================
# Helpers
# ============================================================================

function Write-Info    { param([string]$Msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $Msg }
function Write-Success { param([string]$Msg) Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $Msg }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Skip    { param([string]$Msg) Write-Host "[SKIP] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }

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
        [string]$Default = "n"
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

    Write-Info "Pipe mode detected. Downloading claude-setup repository for config files..."
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "claude-setup-$(Get-Random)"
    $script:CleanupTemp = $tempDir

    if (Test-Command git) {
        $oldPref = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        & git clone --depth 1 https://github.com/ataaki/claude-setup.git $tempDir 2>&1 | Out-Null
        $ErrorActionPreference = $oldPref
        if (Test-Path (Join-Path $tempDir "config")) {
            $script:ScriptDir = $tempDir
        } else {
            Write-Warn "git clone failed. Plugin removal will be skipped."
            return
        }
    } elseif (Test-Command Invoke-WebRequest) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $archive = Join-Path $tempDir "repo.zip"
        Invoke-WebRequest -Uri "https://github.com/ataaki/claude-setup/archive/refs/heads/main.zip" -OutFile $archive -UseBasicParsing
        Expand-Archive -Path $archive -DestinationPath $tempDir -Force
        $script:ScriptDir = Join-Path $tempDir "claude-setup-main"
    } else {
        Write-Warn "Cannot download config files. Plugin removal will be skipped."
        return
    }

    if (-not (Test-Path (Join-Path $script:ScriptDir "config"))) {
        Write-Warn "Failed to download config files. Plugin removal will be skipped."
        return
    }

    Write-Success "Config files downloaded to temp directory"
}

# ============================================================================
# Confirmation
# ============================================================================

Write-Host ""
Write-Host "============================================"
Write-Host "  Claude Code Setup - Uninstall"
Write-Host "============================================"
Write-Host ""
Write-Host "  This can remove:"
Write-Host "  - Config installed by the setup (CLAUDE.md, session-resume, hook)"
Write-Host "  - Plugins installed by the setup"
Write-Host "  - Claude Code CLI itself"
Write-Host ""
if (-not (Read-YesNo "Continue?")) {
    Write-Host "Cancelled."
    return
}

# ============================================================================
# 1. Remove CLAUDE.md (with backup restore option)
# ============================================================================

Write-Host ""
Write-Info "--- CLAUDE.md ---"

$claudeMd = Join-Path $ClaudeDir "CLAUDE.md"

if (Test-Path $claudeMd) {
    Remove-Item $claudeMd -Force
    Write-Success "CLAUDE.md removed"

    # Check for backups
    $backups = Get-ChildItem -Path $ClaudeDir -Filter "CLAUDE.md.backup.*" -File -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending
    $latestBackup = $backups | Select-Object -First 1

    if ($latestBackup) {
        if (Read-YesNo "Restore backup ($($latestBackup.FullName))?") {
            Copy-Item $latestBackup.FullName $claudeMd
            Write-Success "Backup restored"
        }
    }
} else {
    Write-Skip "CLAUDE.md not found"
}

# ============================================================================
# 2. Remove session-resume scripts
# ============================================================================

Write-Info "--- session-resume ---"

$sessionResumeSh = Join-Path $ClaudeDir "scripts/session-resume.sh"
$sessionResumePs1 = Join-Path $ClaudeDir "scripts/session-resume.ps1"

if (Test-Path $sessionResumePs1) {
    Remove-Item $sessionResumePs1 -Force
    Write-Success "session-resume.ps1 removed"
} else {
    Write-Skip "session-resume.ps1 not found"
}

if (Test-Path $sessionResumeSh) {
    Remove-Item $sessionResumeSh -Force
    Write-Success "session-resume.sh removed"
} else {
    Write-Skip "session-resume.sh not found"
}

# ============================================================================
# 3. Remove hook from settings.json
# ============================================================================

Write-Info "--- Hook settings.json ---"

$settingsFile = Join-Path $ClaudeDir "settings.json"

if (Test-Path $settingsFile) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Copy-Item $settingsFile "$settingsFile.backup.$timestamp"

    try {
        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json

        if ($settings.hooks -and $settings.hooks.UserPromptSubmit -and
            $settings.hooks.UserPromptSubmit[0].hooks) {

            # Filter out session-resume hooks
            $filteredHooks = @($settings.hooks.UserPromptSubmit[0].hooks | Where-Object {
                -not ($_.command -and $_.command -match "session-resume")
            })

            $settings.hooks.UserPromptSubmit[0].hooks = $filteredHooks
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
            Write-Success "session-resume hook removed from settings.json"
        } else {
            Write-Skip "No UserPromptSubmit hook in settings.json"
        }
    } catch {
        Write-Warn "settings.json is malformed. Edit manually to remove the session-resume hook."
    }
} else {
    Write-Skip "settings.json not found"
}

# ============================================================================
# 4. Optionally remove plugins
# WARNING: must run BEFORE section 5 (CLI uninstall) — needs claude command
# ============================================================================

Write-Host ""
if (Read-YesNo "Also remove plugins installed by the setup?") {
    Write-Info "Removing plugins..."

    if (Test-Command claude) {
        # Ensure config dir is available (downloads repo in pipe mode)
        Ensure-ConfigDir
        $PluginsFile = Join-Path $ScriptDir "config/plugins.txt"

        $plugins = @()
        if (Test-Path $PluginsFile) {
            $plugins = @(Get-Content $PluginsFile | ForEach-Object {
                $line = $_.Trim()
                if ($line -and -not $line.StartsWith("#")) {
                    ($line -split '#')[0].Trim()
                }
            } | Where-Object { $_ })
        } else {
            Write-Warn "plugins.txt not found ($PluginsFile). Use 'claude plugins list' to see installed plugins."
        }

        foreach ($plugin in $plugins) {
            try {
                & claude plugins uninstall $plugin 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "  $plugin removed"
                } else {
                    Write-Skip "  $plugin (not installed or error)"
                }
            } catch {
                Write-Skip "  $plugin (not installed or error)"
            }
        }

        # Remove marketplaces added by install
        Write-Info "Removing marketplaces..."
        $marketplaces = @(
            "anthropics/claude-plugins-official",
            "obra/superpowers",
            "upstash/context7",
            "anthropics/claude-code"
        )
        foreach ($mp in $marketplaces) {
            $mpName = ($mp -split '/')[-1]
            try {
                & claude plugins marketplace remove "https://github.com/$mp" *>$null
                Write-Success "  $mpName removed"
            } catch {
                Write-Skip "  $mpName (not found or error)"
            }
        }
    } else {
        Write-Warn "Claude CLI not available. Cannot uninstall plugins via CLI."
        foreach ($dir in @((Join-Path $ClaudeDir "plugins"), (Join-Path $ClaudeDir "installed-plugins"))) {
            if (Test-Path $dir) {
                Remove-Item $dir -Recurse -Force
                Write-Success "Directory removed: $dir"
            }
        }
    }
} else {
    Write-Skip "Plugins kept"
}

# ============================================================================
# 5. Optionally uninstall Claude Code CLI
# ============================================================================

Write-Host ""
if (Read-YesNo "Also uninstall Claude Code CLI?") {
    Write-Info "Uninstalling CLI..."
    $uninstalled = $false

    # npm
    if ((Test-Command npm.cmd) -and (& npm.cmd list -g @anthropic-ai/claude-code 2>$null)) {
        & npm.cmd uninstall -g @anthropic-ai/claude-code
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

    # Fallback: remove binary in PATH
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        $claudeBin = $claudeCmd.Source
        if ($claudeBin -and (Test-Path $claudeBin)) {
            Remove-Item $claudeBin -Force
            Write-Success "Binary removed ($claudeBin)"
            $uninstalled = $true
        }
    }

    # Known locations
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
    }
} else {
    Write-Skip "Claude Code CLI kept"
}

# Cleanup temp directory
if ($CleanupTemp -and (Test-Path $CleanupTemp)) {
    Remove-Item $CleanupTemp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Success "Uninstall complete."
Write-Host ""
