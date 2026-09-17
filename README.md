<div align="center">

# ⚡ Antigravity Skills Hub

### The Unified 8-Stage SDLC Agentic Skills Ecosystem

[![Architect](https://img.shields.io/badge/Architect-Jamemm-blue?style=flat-square&logo=github)](https://github.com/JameMy0001)
[![Skills](https://img.shields.io/badge/Skills-61%20Production--Grade-10B981?style=flat-square)](./Skills)
[![Platforms](https://img.shields.io/badge/Platforms-Antigravity%20%7C%20Cursor%20%7C%20Claude-purple?style=flat-square)](./setup.sh)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=flat-square)](./LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-JameMy0001-181717?style=flat-square&logo=github)](https://github.com/JameMy0001/antigravity-skills-hub)

*A production-grade, interconnected cognitive skill ecosystem for autonomous AI coding agents*

</div>

---

## 👨‍💻 Creator & Credits

This centralized skills architecture was conceived, curated, and engineered by **Jamemm** ([@JameMy0001](https://github.com/JameMy0001)).

| Role | Work |
|---|---|
| **System Architect** | Designed the 8-Stage SDLC Lifecycle and unified auto-dispatch routing directives |
| **Knowledge Graph Engineer** | Built the Obsidian visual workflow canvas and bidirectional wikilink mesh across 61 skills |
| **Multi-Platform Integration** | Cross-agent symlinking for Google Antigravity, Cursor IDE, Claude Code & Hermes Agent |
| **Curator & Maintainer** | Evaluated, formatted, and standardized skills from 10+ AI frameworks on the system |

📬 Contact: [Jamerrmool@gmail.com](mailto:Jamerrmool@gmail.com) · GitHub: [@JameMy0001](https://github.com/JameMy0001)

---

## 🏗️ Architecture Overview

This vault implements an **8-Stage SDLC Skill Dispatch System** — one centralized Obsidian knowledge graph that auto-routes to the right skill for every coding task, across every major AI agent platform simultaneously.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                  AGENTIC SKILLS HUB — 8-Stage SDLC                     │
│                                                                         │
│  01 New Features  ──►  tdd-workflow · brainstorming · writing-plans    │
│  02 Bug Fixing    ──►  systematic-debugging · orch-fix-defect          │
│  03 Database      ──►  database-migrations                              │
│  04 Web/Frontend  ──►  claude-design · modern-web-guidance · playwright│
│  05 Security      ──►  review-security · determine_threat_model        │
│  06 Git/Release   ──►  git-workflow · github-pr-workflow · finishing   │
│  07 Exploration   ──►  codebase-onboarding · llm-wiki · tmux          │
│  08 Office/Docs   ──►  docx · xlsx · powerpoint · pdf · ocr           │
│                                                                         │
│  🔀 Auto-Dispatch Directive → routes every request automatically       │
│  🕸️  Obsidian Graph → bidirectional [[Wikilinks]] across all skills    │
│  🔗  Symlinks → ~/.gemini/config/skills && ~/.cursor/skills            │
└─────────────────────────────────────────────────────────────────────────┘
```

### Multi-Platform Integration
One vault. Every AI agent platform. Simultaneously.

| Platform | Integration Path | Status |
|---|---|---|
| **Google Antigravity** | `~/.gemini/config/skills` | ✅ Symlinked |
| **Cursor IDE** | `~/.cursor/skills` | ✅ Symlinked |
| **Claude Code** | `~/.claude/skills` | ✅ Compatible |
| **Hermes Agent** | `~/.hermes/skills` | ✅ Compatible |
| **Obsidian** | Native vault with Graph View | ✅ Active |

---

## ⚡ Quick Start

### Prerequisites
- macOS, Linux, or Windows (WSL)
- Python 3.9+ for companion scripts
- [Obsidian](https://obsidian.md) (optional, for Knowledge Graph UI)

### Installation (One Command)

```bash
# 1. Clone the repository
git clone https://github.com/JameMy0001/antigravity-skills-hub.git
cd antigravity-skills-hub

# 2. Configure git for Thai/Emoji filenames (important!)
git config core.precomposeunicode true
git config core.quotepath false

# 3. Run the installer (symlinks + dependencies)
chmod +x setup.sh && ./setup.sh
```

The `setup.sh` script will:
- 🔗 Create symlinks → `~/.gemini/config/skills` and `~/.cursor/skills`
- 📦 Install Python dependencies via `pip` or `uv`
- ✅ Run `verify_skills_vault.py` to confirm all 61 skills are active

#### Windows Users
```powershell
# Run as Administrator
.\setup.ps1
```

### Manual Symlink (Advanced)
```bash
# Google Antigravity
mkdir -p ~/.gemini/config
ln -s "$(pwd)/Skills" ~/.gemini/config/skills

# Cursor IDE
mkdir -p ~/.cursor
ln -s "$(pwd)/Skills" ~/.cursor/skills
```

---

## 📚 Skill Catalog (61 Skills)

### 🟢 Stage 01 — New Features & Business Logic

| Skill | Description |
|---|---|
| `tdd-workflow` | Red-Green-Refactor TDD with 80%+ coverage: unit, integration & E2E tests |
| `brainstorming` | Explore intent, requirements, and design trade-offs before implementation |
| `writing-plans` | Write comprehensive, bite-sized implementation plans from specs |
| `api-design` | REST API design: resources, status codes, pagination, versioning, rate limiting |
| `backend-patterns` | Node.js/Express/Next.js backend architecture and data access patterns |
| `subagent-driven-development` | Dispatch parallel implementer subagents for independent tasks |
| `canvas` | Live React canvas artifacts: data visualizations, interactive explorations |
| `goal` | Long-running goal achievement with thoroughness and iteration |

### 🔴 Stage 02 — Bug Fixing & Defect Resolution

| Skill | Description |
|---|---|
| `systematic-debugging` | 4-phase root cause analysis: understand, reproduce, isolate, fix |
| `orch-fix-defect` | Orchestrate bug fixing: failing regression test → fix → review → commit |
| `agent-introspection-debugging` | Self-debugging for AI agent failures with structured diagnosis reports |

### 🟠 Stage 03 — Database & Migrations

| Skill | Description |
|---|---|
| `database-migrations` | Zero-downtime migrations: PostgreSQL, MySQL, Prisma, Drizzle, Kysely |

### 🔵 Stage 04 — Web & Frontend

| Skill | Description |
|---|---|
| `claude-design` | World-class UI/UX: 4-layer atomic button craft, 7 archetypes, 10-point quality gates |
| `modern-web-guidance` | MANDATORY first-check for HTML/CSS/JS tasks — checks latest web APIs |
| `playwright-cli` | Browser automation, E2E testing, screenshots, web scraping |
| `playwright-trace` | Inspect Playwright trace zip files: actions, requests, console errors |
| `chrome-extensions` | Build Chrome Extensions with Manifest V3: service workers, content scripts |
| `visualize` | Inline charts, Mermaid diagrams, and compact visual representations |
| `deploy-with-vercel` | Deploy web projects to Vercel with zero config |

### 🟡 Stage 05 — Security & Code Quality

| Skill | Description |
|---|---|
| `review-security` | Security review subagent for code changes |
| `determine_threat_model` | Build threat models: entry points, trust boundaries, attack surfaces |
| `error-handling` | Typed errors, retries, circuit breakers in TypeScript/Python/Go |
| `verification-before-completion` | Verify before claiming done — test evidence before assertions |
| `receiving-code-review` | Process code review feedback with technical rigor and honest debate |
| `review-bugbot` | Bugbot review subagent for automated bug detection |
| `review` | General code review for quality, maintainability, and correctness |

### 🟣 Stage 06 — Git, Commits & Release

| Skill | Description |
|---|---|
| `git-workflow` | Branching strategies, Conventional Commits, merge vs rebase, conflict resolution |
| `github-pr-workflow` | PR lifecycle: branch, commit, open PR, monitor CI, merge safely |
| `using-git-worktrees` | Isolated feature work via git worktrees |
| `finishing-a-development-branch` | Integration readiness: verify tests, clean worktrees, prepare PR |
| `split-to-prs` | Split large changes into small, reviewable pull requests |
| `autopilot` | Keep PRs merge-ready by triaging comments and fixing CI in a loop |
| `new-repo` | Create and push Cursor-hosted repositories |
| `share` | Save, back up, or share current project |
| `origin` | Install/sign in to the Cursor origin CLI |

### ⚪ Stage 07 — Codebase Exploration & Tooling

| Skill | Description |
|---|---|
| `codebase-onboarding` | Architectural recon, key entry points, conventions & CLAUDE.md generation |
| `llm-wiki` | Build and query interlinked Markdown knowledge base for deep research |
| `tmux` | Remote-control tmux sessions for persistent interactive CLI processes |
| `architecture-diagram` | Dark-themed SVG architecture and system flow diagrams in interactive HTML |
| `excalidraw` | Hand-drawn Excalidraw JSON diagrams: flowcharts, sequence diagrams, maps |
| `baoyu-infographic` | Convert technical concepts into visual infographics with 21 layouts/styles |
| `create-skill` | Create new Cursor Agent Skills with SKILL.md structure |
| `create-rule` | Create persistent AI guidance rules and coding standards |
| `create-hook` | Create Cursor hooks for automated agent event behaviors |
| `create-subagent` | Define and spawn specialized subagents for delegated tasks |
| `automate` | Create Cursor Automations for workflow automation |
| `sdk` | Build apps and scripts with the Cursor SDK (TypeScript/Python) |
| `statusline` | Configure custom CLI status line with session context |
| `update-cli-config` | Modify Cursor CLI configuration settings |
| `update-cursor-settings` | Modify Cursor/VSCode user settings.json |
| `loop` | Run prompts or skills on recurring intervals |
| `onboard` | Onboard yourself or others into a codebase quickly |
| `migrate-to-skills` | Migrate legacy workflows to modern Obsidian skills |
| `rename-chat` | Rename current chat conversation for organization |
| `shell` | Execute shell commands safely in the agent context |

### 🟤 Stage 08 — Productivity & Office Documents

| Skill | Description |
|---|---|
| `docx` | Create, inspect, modify Word `.docx` documents, tracked changes, tables, styles |
| `xlsx` | Create, read, edit Excel `.xlsx` spreadsheets, formulas, multi-sheet management |
| `powerpoint` | Create, read, edit PowerPoint `.pptx` presentations and slide thumbnails |
| `pdf` | Create, merge, split, fill PDF forms, inspect bounding boxes, extract text |
| `ocr-and-documents` | Extract text, tables, math from scanned PDFs and images via PyMuPDF/Marker |
| `document-design` | Editorial publication styling, 60-30-10 color harmony, Tufte tables, PDF pipeline |

---

## 🧭 Knowledge Graph

Open this vault in [Obsidian](https://obsidian.md) to explore the full bidirectional knowledge graph:

1. Open Obsidian → **Open folder as vault** → select this repo directory
2. Press `Cmd+G` (Mac) or `Ctrl+G` (Windows) → **Graph View**
3. Open `00 - 🧭 Skills Dashboard.md` for the command center
4. Open `01 - 🗺️ Skills Workflow.canvas` for the visual workflow map

All 61 skills are interconnected via `[[Wikilinks]]` with color-coded stage groupings in the Graph.

---

## 🔍 Verification

Verify your vault installation is 100% operational:

```bash
# Basic check (auto-detects vault from script location)
python3 verify_skills_vault.py

# With iCloud mirror parity check
ICLOUD_SKILLS_PATH="/path/to/your/icloud/vault" python3 verify_skills_vault.py --check-mirror

# Custom vault location
SKILLS_VAULT_PATH="/custom/path/to/vault" python3 verify_skills_vault.py
```

---

## 📖 How to Cite

If you use this skills system in your work or research:

```bibtex
@software{jamemm2026antigravity,
  author = {Jamemm},
  title = {Antigravity Skills Hub: Unified 8-Stage SDLC Agentic Skills Ecosystem},
  url = {https://github.com/JameMy0001/antigravity-skills-hub},
  version = {1.0.0},
  year = {2026},
}
```

Or see [CITATION.cff](./CITATION.cff) for the full machine-readable citation.

---

## 📜 License

Copyright © 2026 **Jamemm** ([@JameMy0001](https://github.com/JameMy0001))

This repository is licensed under the **MIT License** — see [LICENSE](./LICENSE) for details.

Third-party component attributions are documented in [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md).

---

<div align="center">

*Built with ❤️ by [Jamemm](https://github.com/JameMy0001) · Star ⭐ this repo if it helps you build better AI agents*

</div>
