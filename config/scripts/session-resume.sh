#!/bin/bash
# session-resume.sh — Forces CLAUDE.md workflow on every prompt + detects PROGRESS.md

# ===== MANDATORY WORKFLOW REMINDER =====
echo "=== CLAUDE.MD WORKFLOW — OBLIGATOIRE — PRIME SUR TOUT ==="
echo "STOP. Avant de repondre, lis ~/.claude/CLAUDE.md et suis le workflow."
echo "PEU IMPORTE la demande (feature, bug, question, refactor, typo), tu DOIS suivre TOUTES les etapes :"
echo "1. BRAINSTORM — Reflexion en profondeur (meme pour un bug: comprendre la cause racine)"
echo "2. PLAN — Plan detaille (meme court pour une petite tache)"
echo "3. IMPLEMENT — TDD strict + edge cases"
echo "4. SECURE — Checklist securite"
echo "5. VERIFY — Preuves que ca marche (tests, build)"
echo "6. REVIEW — Code review"
echo "7. PROGRESS — Mise a jour du suivi"
echo ""
echo "CE WORKFLOW PRIME SUR LES SKILLS. Les skills (brainstorming, debugging, etc.) sont des OUTILS, pas des remplacements."
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

# Check for plan files using find to avoid glob expansion issues on empty dirs
PLANS_DIR="$PWD/docs/plans"
if [ -d "$PLANS_DIR" ]; then
    LATEST_PLAN=$(find "$PLANS_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r | head -1)
    if [ -n "$LATEST_PLAN" ]; then
        echo "Plan disponible: $LATEST_PLAN"
    fi
fi
