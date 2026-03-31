# session-resume.ps1 — Compact workflow reminder + session resume detection

# ===== WORKFLOW REMINDER (kept short to avoid context noise) =====
Write-Output "=== WORKFLOW REMINDER ==="
Write-Output "Classify task: MICRO (typo/config) | SMALL (bugfix/small feature) | STANDARD (feature/architecture)"
Write-Output "Then follow the matching workflow from CLAUDE.md. Do NOT skip tiers."
Write-Output "Rules: English for code/docs/commits. No Co-Authored-By. LTS versions only. Update docs immediately."
Write-Output "=== END ==="

# ===== SESSION RESUME =====
$ProgressFile = Join-Path $PWD "PROGRESS.md"

if (Test-Path $ProgressFile) {
    Write-Output ""
    Write-Output "PROGRESS.md detected - read it now to resume where you left off."
    Write-Output "Path: $ProgressFile"
}

# Check for plan files
$PlansDir = Join-Path $PWD "docs/plans"
if (Test-Path $PlansDir) {
    $LatestPlan = Get-ChildItem -Path $PlansDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($LatestPlan) {
        Write-Output "Latest plan: $($LatestPlan.FullName)"
    }
}
