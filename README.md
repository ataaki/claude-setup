# Claude Code Setup

Automatic installation of Claude Code with a complete professional configuration.

## What gets installed

### Claude Code CLI
- Native installation (preferred) or npm (fallback)
- Node.js installed automatically if needed

### Global configuration (`~/.claude/CLAUDE.md`)
A compact universal framework (~60 lines) applied to **all your projects**:

- **Adaptive workflow** with 3 tiers: MICRO (typo/config), SMALL (bugfix), STANDARD (feature) — right amount of process for each task size
- **TDD, security, a11y, performance checklists** in a separate reference doc (`docs/workflow-reference.md`) — consulted when needed, not memorized
- **LTS versions verified** in real time via web search
- **Documentation always up to date**: README, .env.example, local CLAUDE.md, PROGRESS.md
- **Session resume**: PROGRESS.md + automatic hook
- **Git conventions**: Conventional Commits + standardized branches
- **Auto-init files**: README, .env.example, CI/CD, local CLAUDE.md

### Plugins
Loaded from [`config/plugins.txt`](config/plugins.txt) (single source of truth).

| Plugin | Role |
|--------|------|
| superpowers | Advanced workflow (brainstorm, plans, TDD, debug, review) |
| frontend-design | Production-grade web interfaces |
| security-guidance | Security guidance |
| context7 | Up-to-date library documentation |
| code-simplifier | Code simplification |
| playwright | Browser E2E testing |
| typescript-lsp | TypeScript support |
| pyright-lsp | Python support |
| explanatory-output-style | Educational explanations |
| learning-output-style | Interactive learning mode |
| ralph-loop | Looping commands |
| claude-md-management | CLAUDE.md management |

## Installation

### Linux / macOS (Bash)

#### Option 1: Clone + run (recommended)

```bash
git clone https://github.com/ataaki/claude-setup.git
cd claude-setup
./install.sh
```

#### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/ataaki/claude-setup/main/install.sh | bash
```

In pipe mode, the script auto-downloads the repository to a temp directory and uses non-interactive defaults (no uninstall, fresh install).

### Windows (PowerShell)

#### Option 1: Clone + run (recommended)

```powershell
git clone https://github.com/ataaki/claude-setup.git
cd claude-setup
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

#### Option 2: One-liner

```powershell
irm https://raw.githubusercontent.com/ataaki/claude-setup/main/install.ps1 | iex
```

In pipe mode, the script auto-downloads the repository to a temp directory and uses non-interactive defaults.

### Existing installation

If Claude Code is already installed, the script will ask:

1. **Uninstall and reinstall?** (default: no)
   - If yes: selective uninstall (CLI, config, plugins — each optional)
   - Then fresh install
2. **Install config and plugins anyway?** (default: yes)
   - Skips CLI install, applies config and plugins only

## Uninstall

### Linux / macOS

```bash
./uninstall.sh
```

CLI uninstall covers: npm, brew, apt/dpkg, snap, and known binary locations.

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

CLI uninstall covers: npm, winget, scoop, chocolatey, and known binary locations.

### What the uninstall does

1. Remove CLAUDE.md (with option to restore backup)
2. Remove session-resume hook scripts
3. Remove hook from settings.json
4. **Optionally** remove all plugins installed by the setup
5. **Optionally** uninstall Claude Code CLI itself

## Customization

### Edit the framework
Edit `~/.claude/CLAUDE.md` to adapt the rules to your needs.

### Add or remove plugins
Edit [`config/plugins.txt`](config/plugins.txt) — one plugin per line, `#` for comments.

Then re-run `./install.sh` (or `.\install.ps1` on Windows) to apply changes.

### Skip a workflow step
Say "skip brainstorm", "skip tdd", "skip security", etc. in your conversation with Claude.

## Structure

```
claude-setup/
├── install.sh                 # Install script - Bash (Linux/macOS)
├── install.ps1                # Install script - PowerShell (Windows)
├── uninstall.sh               # Uninstall script - Bash (Linux/macOS)
├── uninstall.ps1              # Uninstall script - PowerShell (Windows)
├── README.md
├── config/
│   ├── CLAUDE.md              # Universal framework (~60 lines, compact)
│   ├── settings.json          # Claude Code hooks
│   ├── plugins.txt            # Plugin list (shared by install + uninstall)
│   └── scripts/
│       ├── session-resume.sh  # Session resume hook (Bash)
│       └── session-resume.ps1 # Session resume hook (PowerShell)
├── docs/
│   └── workflow-reference.md  # Detailed checklists (security, a11y, perf, etc.)
```

## Session resume

When you relaunch Claude Code in a project:
1. The hook automatically detects `PROGRESS.md`
2. Claude reads the project state
3. Say "resume" to continue exactly where you left off

## License

MIT
