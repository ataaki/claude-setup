#!/bin/bash
# session-resume.sh — Detects PROGRESS.md and reminds Claude to read it

PROGRESS_FILE="$PWD/PROGRESS.md"

if [ -f "$PROGRESS_FILE" ]; then
    echo "RAPPEL: Un fichier PROGRESS.md existe dans ce projet."
    echo "Lis-le avec Read pour savoir ou tu en etais."
    echo "Chemin: $PROGRESS_FILE"
fi

# Also check for plan files
PLANS_DIR="$PWD/docs/plans"
if [ -d "$PLANS_DIR" ]; then
    LATEST_PLAN=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$LATEST_PLAN" ]; then
        echo "Plan disponible: $LATEST_PLAN"
    fi
fi
