#!/bin/bash
# session-resume.sh — Forces CLAUDE.md workflow on every prompt + detects PROGRESS.md

# ===== MANDATORY WORKFLOW REMINDER =====
echo "=== CLAUDE.MD WORKFLOW — OBLIGATOIRE ==="
echo "PEU IMPORTE la taille ou la complexite de la demande, tu DOIS suivre le workflow CLAUDE.md :"
echo "1. BRAINSTORM — Reflexion en profondeur, remise en question"
echo "2. PLAN — Plan detaille"
echo "3. IMPLEMENT — TDD strict + edge cases"
echo "4. SECURE — Checklist securite"
echo "5. VERIFY — Preuves que ca marche"
echo "6. REVIEW — Code review"
echo "7. PROGRESS — Mise a jour du suivi"
echo ""
echo "Regles absolues : anglais pour code/docs/commits, pas de Co-Authored-By, pas de worktrees, versions LTS verifiees, doc toujours a jour."
echo "NE SAUTE AUCUNE ETAPE sauf si l'utilisateur dit explicitement 'skip [etape]'."
echo "=== FIN RAPPEL ==="

# ===== SESSION RESUME =====
PROGRESS_FILE="$PWD/PROGRESS.md"

if [ -f "$PROGRESS_FILE" ]; then
    echo ""
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
