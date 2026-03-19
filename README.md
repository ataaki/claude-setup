# Claude Code Setup

Installation automatique de Claude Code avec une configuration professionnelle complete.

## Ce qui est installe

### Claude Code CLI
- Installation native (prioritaire) ou via npm (fallback)
- Node.js installe automatiquement si necessaire

### Configuration globale (`~/.claude/CLAUDE.md`)
Un framework universel qui s'applique a **tous vos projets** :

- **Workflow en 7 etapes** : brainstorm, plan, TDD, securite, verification, review, suivi
- **Reflexion en profondeur** : chaque decision est challengee avec des alternatives
- **TDD strict** avec tests des edge cases (null, limites, auth, timeout, injection, concurrence)
- **Checklist securite niveau B** : OWASP top 10, CORS, headers, rate limiting, scan deps
- **Versions LTS verifiees** en temps reel via recherche web
- **Documentation toujours a jour** : README, .env.example, CLAUDE.md local, PROGRESS.md
- **Reprise apres coupure** : PROGRESS.md + hook automatique
- **Accessibilite web** (WCAG AA)
- **Performance** : N+1, pagination, index, lazy loading
- **Conventions git** : Conventional Commits + branches normees
- **Logging structure** : niveaux, contexte, pas de donnees sensibles
- **Fichiers d'init** automatiques : README, .env.example, CI/CD, CLAUDE.md local

### Plugins (17)
| Plugin | Role |
|--------|------|
| superpowers | Workflow avance (brainstorm, plans, TDD, debug, review) |
| frontend-design | Interfaces web production-grade |
| security-guidance | Guidance securite |
| context7 | Documentation de librairies a jour |
| code-simplifier | Simplification de code |
| playwright | Tests E2E navigateur |
| typescript-lsp | Support TypeScript |
| pyright-lsp | Support Python |
| explanatory-output-style | Explications pedagogiques |
| learning-output-style | Mode apprentissage interactif |
| greptile | Recherche semantique dans le code |
| ralph-loop | Commandes en boucle |
| claude-md-management | Gestion des CLAUDE.md |

## Installation

### Option 1 : Clone + run

```bash
git clone https://github.com/yujacare/claude-setup.git
cd claude-setup
./install.sh
```

### Option 2 : One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/yujacare/claude-setup/main/install.sh | bash
```

> **Note** : L'option 2 telecharge le script mais a besoin du repo pour les fichiers de config. Preferez l'option 1.

## Desinstallation

```bash
./uninstall.sh
```

Supprime la config et les hooks. Ne desinstalle pas Claude Code ni les plugins.

## Personnalisation

### Modifier le framework
Editez `~/.claude/CLAUDE.md` pour adapter les regles a vos besoins.

### Ajouter des plugins
```bash
claude plugins install <plugin-name>@<marketplace>
```

### Desactiver une etape du workflow
Dites "skip brainstorm", "skip tdd", "skip security", etc. dans votre conversation avec Claude.

## Structure

```
claude-setup/
├── install.sh              # Script d'installation
├── uninstall.sh            # Script de desinstallation
├── README.md               # Ce fichier
├── config/
│   ├── CLAUDE.md           # Framework universel
│   ├── settings.json       # Hooks Claude Code
│   └── scripts/
│       └── session-resume.sh  # Detection PROGRESS.md
```

## Reprise apres coupure

Quand vous relancez Claude Code dans un projet :
1. Le hook detecte automatiquement `PROGRESS.md`
2. Claude lit l'etat du projet
3. Dites "reprends" pour continuer exactement ou vous en etiez

## Licence

MIT
