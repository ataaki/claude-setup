#!/bin/bash
# session-resume.sh — Compact workflow reminder + session resume detection

# ===== WORKFLOW REMINDER (kept short to avoid context noise) =====
echo "=== WORKFLOW REMINDER ==="
echo "Classify task: MICRO (typo/config) | SMALL (bugfix/small feature) | STANDARD (feature/architecture)"
echo "Then follow the matching workflow from CLAUDE.md. Do NOT skip tiers."
echo "Rules: English for code/docs/commits. No Co-Authored-By. LTS versions only. Update docs immediately."
echo "=== END ==="

# ===== SESSION RESUME =====
PROGRESS_FILE="$PWD/PROGRESS.md"

if [ -f "$PROGRESS_FILE" ]; then
    echo ""
    echo "PROGRESS.md detected — read it now to resume where you left off."
    echo "Path: $PROGRESS_FILE"
fi

# Check for plan files using find to avoid glob expansion issues on empty dirs
PLANS_DIR="$PWD/docs/plans"
if [ -d "$PLANS_DIR" ]; then
    LATEST_PLAN=$(find "$PLANS_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r | head -1)
    if [ -n "$LATEST_PLAN" ]; then
        echo "Latest plan: $LATEST_PLAN"
    fi
fi
