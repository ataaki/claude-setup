# Claude Code Setup

Automatic installation of Claude Code with a complete professional configuration.

## What gets installed

### Claude Code CLI
- Native installation (preferred) or npm (fallback)
- Node.js installed automatically if needed

### Global configuration (`~/.claude/CLAUDE.md`)
A universal framework applied to **all your projects**:

- **7-step workflow**: brainstorm, plan, TDD, security, verify, review, progress tracking
- **Deep reasoning**: every decision is challenged with alternatives
- **Strict TDD** with edge case testing (null, limits, auth, timeout, injection, concurrency)
- **Security checklist level B**: OWASP top 10, CORS, headers, rate limiting, dependency scanning
- **LTS versions verified** in real time via web search
- **Documentation always up to date**: README, .env.example, local CLAUDE.md, PROGRESS.md
- **Session resume**: PROGRESS.md + automatic hook
- **Web accessibility** (WCAG AA)
- **Performance**: N+1, pagination, indexes, lazy loading
- **Git conventions**: Conventional Commits + standardized branches
- **Structured logging**: levels, context, no sensitive data
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
| greptile | Semantic code search |
| ralph-loop | Looping commands |
| claude-md-management | CLAUDE.md management |

## Installation

### Option 1: Clone + run (recommended)

```bash
git clone https://github.com/yujacare/claude-setup.git
cd claude-setup
./install.sh
```

### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/yujacare/claude-setup/main/install.sh | bash
```

In pipe mode, the script auto-downloads the repository to a temp directory and uses non-interactive defaults (no uninstall, fresh install).

### Existing installation

If Claude Code is already installed, the script will ask:

1. **Uninstall and reinstall?** (default: no)
   - If yes: selective uninstall (CLI, config, plugins — each optional)
   - Then fresh install
2. **Install config and plugins anyway?** (default: yes)
   - Skips CLI install, applies config and plugins only

## Uninstall

```bash
./uninstall.sh
```

The uninstall script will:
1. Remove CLAUDE.md (with option to restore backup)
2. Remove session-resume.sh hook
3. Remove hook from settings.json
4. **Optionally** remove all plugins installed by the setup
5. **Optionally** uninstall Claude Code CLI itself

CLI uninstall covers: npm, brew, apt/dpkg, snap, winget (WSL2), and known binary locations.

## Customization

### Edit the framework
Edit `~/.claude/CLAUDE.md` to adapt the rules to your needs.

### Add or remove plugins
Edit [`config/plugins.txt`](config/plugins.txt) — one plugin per line, `#` for comments.

Then re-run `./install.sh` to apply changes.

### Skip a workflow step
Say "skip brainstorm", "skip tdd", "skip security", etc. in your conversation with Claude.

## Structure

```
claude-setup/
├── install.sh                 # Install script (with reinstall + pipe mode support)
├── uninstall.sh               # Uninstall script (config, plugins, CLI)
├── README.md
├── config/
│   ├── CLAUDE.md              # Universal framework
│   ├── settings.json          # Claude Code hooks
│   ├── plugins.txt            # Plugin list (shared by install + uninstall)
│   └── scripts/
│       └── session-resume.sh  # PROGRESS.md detection + workflow reminder
```

## Session resume

When you relaunch Claude Code in a project:
1. The hook automatically detects `PROGRESS.md`
2. Claude reads the project state
3. Say "resume" to continue exactly where you left off

## License

MIT
