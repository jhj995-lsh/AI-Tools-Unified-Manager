# AI Tools Unified Manager

Manage MCP servers, Skills, and configurations across multiple AI coding tools (Claude, Gemini CLI, Codex, OpenCode) from a single script.

## Features

- **Unified management** of MCP servers and Skills shared across 4 AI tools via Junction links
- **One-command init** — auto-creates `shared/mcp`, `shared/skills`, `backups` on first run
- **Portable** — no hardcoded paths; works on any Windows machine and any directory
- **Git version control** — save, rollback, and push your configurations
- **Install skills** from GitHub, ZIP files, or local directories
- **Add/remove MCP** servers to all tools at once
- **Auto-repair** broken Junction links with `.\manage.ps1 repair`

## Quick Start

```powershell
# 1. Clone this repo
git clone https://github.com/jhj995-lsh/AI-Tools-Unified-Manager.git D:\AI

# 2. Enter the directory
cd D:\AI

# 3. Run any command — folders are auto-created on first use
.\manage.ps1 status

# 4. Link your AI tools to the shared directory
.\manage.ps1 repair
```

## Commands

| Command | Description |
|---|---|
| `status` | Overview: Junctions, components, Git, backups |
| `list-mcp` | List all shared MCP servers |
| `list-skills` | List all shared Skills |
| `show-mcp <name>` | Show details of a specific MCP server |
| `show-skill <name>` | Show details of a specific Skill |
| `test-mcp` | Test if MCP servers can start |
| `add-mcp [name]` | Add a new MCP to all 4 tools (interactive) |
| `remove-mcp <name>` | Remove an MCP from all tools |
| `add-skill <source>` | Install a skill (Git URL / ZIP / local dir) |
| `remove-skill <name>` | Remove a skill |
| `git save "msg"` | Stage and commit all changes |
| `git push` | Push to remote repository |
| `git log` | Show commit history |
| `git rollback <hash>` | Rollback to a specific commit |
| `git reset` | Discard all uncommitted changes |
| `backup` | Create a full manual backup |
| `repair` | Fix missing Junction links |
| `version` | Show script version |

## Directory Structure

```
D:\AI\                          (or any directory)
├── manage.ps1                  # Main management script
├── GUIDE.md                    # User guide (Chinese)
├── README.md                   # This file
├── shared\                     # Shared resources (Git-tracked)
│   ├── mcp\                    # MCP server folders
│   └── skills\                 # Skill folders (with SKILL.md)
└── backups\                    # Manual backups
```

## Requirements

- Windows 10/11 with PowerShell 5.1+
- Git installed and in PATH
- AI tools installed: Claude Code, Gemini CLI, Codex, or OpenCode (any subset)

## License

MIT
