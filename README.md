<div align="center">

# Antigravity Skills Hub

### The Unified 8-Stage SDLC Agentic Skills Ecosystem &amp; Living Agent OS

[![Architect](https://img.shields.io/badge/Architect-Jamemm-blue?style=flat-square&logo=github)](https://github.com/JameMy0001)
[![Skills](https://img.shields.io/badge/Skills-68%20Production--Grade-10B981?style=flat-square)](./Skills)
[![CI Pipeline](https://github.com/JameMy0001/antigravity-skills-hub/actions/workflows/ci.yml/badge.svg)](https://github.com/JameMy0001/antigravity-skills-hub/actions/workflows/ci.yml)
[![Web Showcase](https://img.shields.io/badge/Web%20Showcase-Live%20Explorer-6366F1?style=flat-square&logo=googlechrome)](https://jamemy0001.github.io/antigravity-skills-hub/)
[![Platforms](https://img.shields.io/badge/Platforms-Antigravity%20%7C%20Cursor%20%7C%20Claude-purple?style=flat-square)](./setup.sh)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=flat-square)](./LICENSE)

*A production-grade, interconnected cognitive skill ecosystem for autonomous AI coding agents*

[**Explore Live Skills Catalog**](https://jamemy0001.github.io/antigravity-skills-hub/) · [**Documentation**](./Skills) · [**Report an Issue**](../../issues) · [**Request a Skill**](../../issues)

</div>

---

## Creator &amp; Credits

This centralized skills architecture was conceived, curated, and engineered by **Jamemm** ([@JameMy0001](https://github.com/JameMy0001)).

| Role | Work |
|---|---|
| **System Architect** | Designed the 8-Stage SDLC Lifecycle, Curated Skill Evolution Engine (CSEE), and Autonomous Dispatch Protocol v2.1 |
| **Knowledge Graph Engineer** | Built the Obsidian visual workflow canvas and bidirectional wikilink mesh across all 68 skills |
| **Native Systems &amp; CUA Engineer** | Engineered native macOS Accessibility Scanner (`ax-scanner`), Transparent Floating HUD (`computer-use-hud`), and unified bridge (`ag-cua`) |
| **Security &amp; Hardening** | Hardened XML validators against XXE/SSRF, zero broken relative links, and input-validated modular CLI |
| **Multi-Platform Integration** | Cross-agent symlinking for Google Antigravity, Cursor IDE, Claude Code &amp; Hermes Agent |
| **Curator &amp; Maintainer** | Evaluated, formatted, and standardized skills from 10+ AI frameworks into clean Obsidian-native format |

Contact: [Jamerrmool@gmail.com](mailto:Jamerrmool@gmail.com) · GitHub: [@JameMy0001](https://github.com/JameMy0001)

---

## Architecture Overview

Antigravity Skills Hub implements an **8-Stage SDLC Skill Dispatch System** paired with an autonomous **Curated Skill Evolution Engine (CSEE)** and **Native macOS Computer Use (CUA)**. One centralized Obsidian knowledge graph auto-routes to the right skill for every coding task, across every major AI agent platform simultaneously.

<p align="center">
  <img src="docs/assets/architecture-overview.png" alt="Antigravity Skills Hub Architecture Overview" width="100%">
</p>

### Key Architectural Highlights

- **Autonomous Skill Dispatch Engine v2.1**: Abolished interactive confirmation modal bottlenecks. Features zero-modal execution, instantaneous `/boost` activation, and strict single-agent protocol (zero unauthorized background subagents).
- **Curated Skill Evolution Engine (CSEE)**: Automated learning system through real-world usage. Automatically extracts clean heuristics into `learned_patterns.md` and logs telemetry into `00 - 📜 Skills Execution Ledger.md` while enforcing a strict 4-tier anti-bloat filtration gate.
- **Native macOS Computer Use (CUA) Subsystem**: Low-latency GUI automation via native Swift Accessibility API (`ax-scanner`, 5-10ms UI query), floating live indicator (`computer-use-hud`), and unified CLI bridge (`ag-cua` / `codex-agent`).
- **Dual-Vault Parity Engine**: Continuous 100% byte-for-byte synchronization between local development repository and cloud-synced Obsidian mobile vaults via `rsync`.

### Multi-Platform Integration
One vault. Every AI agent platform. Simultaneously.

| Platform | Integration Path | Status |
|---|---|---|
| **Google Antigravity** | `~/.gemini/config/skills` | [PASS] Symlinked |
| **Cursor IDE** | `~/.cursor/skills` | [PASS] Symlinked |
| **Claude Code** | `~/.claude/skills` | [PASS] Compatible |
| **Hermes Agent** | `~/.hermes/skills` | [PASS] Compatible |
| **OpenAI Codex CLI** | `~/.local/bin/codex-agent` | [PASS] Native Binary &amp; Runner |
| **Obsidian** | Native vault with Graph View &amp; Canvas | [PASS] Active |

---

## Quick Start

### Prerequisites
- macOS, Linux, or Windows (WSL)
- Python 3.9+ for companion automation scripts
- [Obsidian](https://obsidian.md) (optional, for Knowledge Graph UI)

### Installation (One Command)

```bash
# 1. Clone the repository
git clone https://github.com/JameMy0001/antigravity-skills-hub.git
cd antigravity-skills-hub

# 2. Configure git for Unicode filenames (Thai + Emoji)
git config core.precomposeunicode true
git config core.quotepath false

# 3. Run the installer (installs all 68 skills + Python dependencies)
chmod +x setup.sh && ./setup.sh
```

---

## Modular CLI Options (`setup.sh`)

The installer supports flexible, targeted installations:

```bash
# Install and link all 68 skills (default)
./setup.sh

# List all available skills organized by SDLC stage
./setup.sh --list

# Link only a specific skill (e.g. claude-design)
./setup.sh --skill claude-design

# Link only skills belonging to a specific SDLC stage (1-8)
./setup.sh --stage 4

# Fast linking without installing Python packages
./setup.sh --stage 1 --no-deps

# Show full usage help
./setup.sh --help
```

### Windows Users
```powershell
# Run as Administrator
.\setup.ps1
```

---

## Autonomous Skill Evolution Engine (`evolve-skill`)

Antigravity Skills Hub features an integrated evolution engine that allows agent skills to get progressively smarter with use, without suffering from prompt bloat or hallucinated rules.

```bash
# Record an execution session and audit heuristics
evolve-skill log --skill systematic-debugging --duration 12.4 --tokens 840 --status PASS

# Distill and inject a verified heuristic
evolve-skill learn --skill systematic-debugging --heuristic "Verify file exists before invoking AST parser"

# Audit all 68 skills for anti-bloat compliance (Rule of 10 & Token budget)
evolve-skill audit
```

### 4-Tier Anti-Bloat Filtration Pipeline
1. **Ephemerality Gate**: Rejects session-specific artifacts, temporary file paths, and one-off bug fixes.
2. **Deduplication Gate**: Performs semantic matching to merge related learnings into existing rules.
3. **Hard-Cap Rule of 10**: Enforces a strict ceiling of maximum 10 active rules per skill. Lower-value rules are pruned when new insights arrive.
4. **Token Budget Gate**: Strictly restricts each rule to under 250 tokens to protect agent context windows.

---

## Interactive Web Showcase

Explore all 68 skills in our responsive web catalog at [**jamemy0001.github.io/antigravity-skills-hub**](https://jamemy0001.github.io/antigravity-skills-hub/):
- **Real-Time Live Search**: Instant filtering by skill name, description, category, or tags.
- **Stage Filtering**: Filter by any of the 8 SDLC stages.
- **One-Click Prompt Copy**: Instantly copy trigger prompts formatted for any AI chat.
- **Dark/Light Theme**: Built with modern CSS custom properties and responsive card grid.

---

## Skill Catalog (68 Skills Across 8 Stages)

### Stage 01 — New Features &amp; Business Logic (8 skills)
| Skill | Description |
|---|---|
| `tdd-workflow` | Red-Green-Refactor TDD with 80%+ coverage: unit, integration &amp; E2E tests |
| `brainstorming` | Explore intent, requirements, and design trade-offs before implementation |
| `writing-plans` | Write comprehensive, bite-sized implementation plans from specs |
| `api-design` | REST API design: resources, status codes, pagination, versioning, rate limiting |
| `backend-patterns` | Node.js/Express/Next.js backend architecture and data access patterns |
| `fastapi-backend` | High-performance async Python APIs: FastAPI, Pydantic v2, Clean Architecture |
| `subagent-driven-development` | Structured plan execution with task-level code reviews and self-contained prompts |
| `architecture-diagram` | Dark-themed SVG architecture and system flow diagrams in interactive HTML |

### Stage 02 — Bug Fixing &amp; Defect Resolution (3 skills)
| Skill | Description |
|---|---|
| `systematic-debugging` | 4-phase root cause analysis: understand, reproduce, isolate, fix |
| `orch-fix-defect` | Orchestrate bug fixing: failing regression test → fix → review → commit |
| `agent-introspection-debugging` | Self-debugging for AI agent failures with structured diagnosis reports |

### Stage 03 — Database &amp; Migrations (2 skills)
| Skill | Description |
|---|---|
| `database-migrations` | Zero-downtime migrations: PostgreSQL, MySQL, Prisma, Drizzle, Kysely |
| `docker-and-compose` | Production containerization: multi-stage Dockerfiles, Compose, non-root security |

### Stage 04 — Web &amp; Frontend Craft (8 skills)
| Skill | Description |
|---|---|
| `claude-design` | World-class UI/UX: 4-layer atomic button craft, 7 archetypes, 10-point quality gates |
| `modern-web-guidance` | MANDATORY first-check for HTML/CSS/JS tasks — checks latest web APIs |
| `nextjs-fullstack` | Next.js 15 App Router, React Server Components (RSC), Server Actions &amp; caching |
| `canvas` | Live React canvas artifacts: data visualizations, interactive explorations |
| `playwright-cli` | Browser automation, E2E testing, screenshots, web scraping |
| `playwright-trace` | Inspect Playwright trace zip files: actions, requests, console errors |
| `chrome-extensions` | Build Chrome Extensions with Manifest V3: service workers, content scripts |
| `visualize` | Inline charts, Mermaid diagrams, and compact visual representations |

### Stage 05 — Security &amp; Code Quality (8 skills)
| Skill | Description |
|---|---|
| `review-security` | Security review subagent for code changes |
| `determine_threat_model` | Build threat models: entry points, trust boundaries, attack surfaces |
| `error-handling` | Typed errors, retries, circuit breakers in TypeScript/Python/Go |
| `verification-before-completion` | Verify before claiming done — test evidence before assertions |
| `no-emoji-minimalism` | Strict plain text typography &amp; zero decorative emojis in code, commits, and docs |
| `receiving-code-review` | Process code review feedback with technical rigor and honest debate |
| `review-bugbot` | Bugbot review subagent for automated bug detection |
| `review` | General code review for quality, maintainability, and correctness |

### Stage 06 — Git, Commits &amp; Release Flow (11 skills)
| Skill | Description |
|---|---|
| `git-workflow` | Branching strategies, Conventional Commits, merge vs rebase, conflict resolution |
| `github-pr-workflow` | PR lifecycle: branch, commit, open PR, monitor CI, merge safely |
| `kubernetes-manifests` | Production Kubernetes manifests: Deployments, Services, Ingress, Probes |
| `using-git-worktrees` | Isolated feature work via git worktrees |
| `finishing-a-development-branch` | Integration readiness: verify tests, clean worktrees, prepare PR |
| `split-to-prs` | Split large changes into small, reviewable pull requests |
| `autopilot` | Keep PRs merge-ready by triaging comments and fixing CI in a loop |
| `deploy-with-vercel` | Deploy web projects to Vercel with zero config |
| `new-repo` | Create and push Cursor-hosted repositories |
| `share` | Save, back up, or share current project |
| `origin` | Install/sign in to the Cursor origin CLI |

### Stage 07 — Tooling, Orchestration &amp; Science (22 skills)
| Skill | Description |
|---|---|
| `codebase-onboarding` | Architectural recon, key entry points, conventions &amp; CLAUDE.md generation |
| `codex-harness-agent` | OpenAI Agents API, Codex Cloud Harness, session state &amp; Computer Use |
| `llm-wiki` | Build and query interlinked Markdown knowledge base for deep research |
| `skill-evolution` | Curated anti-bloat skill evolution engine with Rule of 10 hard-cap |
| `tmux` | Remote-control tmux sessions for persistent interactive CLI processes |
| `excalidraw` | Hand-drawn Excalidraw JSON diagrams: flowcharts, sequence diagrams, maps |
| `baoyu-infographic` | Convert technical concepts into visual infographics with 21 layouts/styles |
| `create-skill` | Author new Agent Skills with complete reference specifications &amp; examples |
| `create-rule` | Create persistent AI guidance rules and coding standards |
| `create-hook` | Create Cursor hooks for automated agent event behaviors |
| `create-subagent` | Define and spawn specialized subagents for delegated tasks |
| `automate` | Create Cursor Automations for workflow automation |
| `goal` | Long-running goal achievement with thoroughness and iteration |
| `sdk` | Build apps and scripts with the Cursor SDK (TypeScript/Python) |
| `statusline` | Configure custom CLI status line with session context |
| `update-cli-config` | Modify Cursor CLI configuration settings |
| `update-cursor-settings` | Modify Cursor/VSCode user settings.json |
| `loop` | Run prompts or skills on recurring intervals |
| `onboard` | Onboard yourself or others into a codebase quickly |
| `migrate-to-skills` | Migrate legacy workflows to modern Obsidian skills |
| `rename-chat` | Rename current chat conversation for organization |
| `shell` | Execute shell commands safely in the agent context |

### Stage 08 — Productivity &amp; Office Documents (6 skills)
| Skill | Description |
|---|---|
| `document-design` | Editorial publication styling, 60-30-10 color harmony, Tufte tables, Anthropic whitepaper spec |
| `docx` | Create, inspect, modify Word `.docx` documents, tracked changes, tables, styles |
| `xlsx` | Create, read, edit Excel `.xlsx` spreadsheets, formulas, multi-sheet management |
| `powerpoint` | Create, read, edit PowerPoint `.pptx` presentations and slide thumbnails |
| `pdf` | Create, merge, split, fill PDF forms, inspect bounding boxes, extract text |
| `ocr-and-documents` | Extract text, tables, math from scanned PDFs and images via PyMuPDF/Marker |

---

## Security Hardening &amp; Quality Engineering

This vault is engineered to production standards:
- **XML Security**: All Office document validators (`docx`, `powerpoint`) enforce `resolve_entities=False` and `no_network=True` to eliminate XML External Entity (XXE) and SSRF risks.
- **Zero Broken Links**: 100% relative link integrity verified across all 68 skills.
- **Single-Agent Protocol**: Strict prohibition on autonomous runaway subagents to eliminate token exhaustion.
- **Continuous Integration**: Automated GitHub Actions testing YAML frontmatter, directory structures, script compilation, and link integrity on every push.
- **Anti-Bloat Heuristic Audit**: Enforced Rule of 10 and token limits in CI before any skill modifications can be merged.

---

## Obsidian Knowledge Graph

Open this repository directly in [Obsidian](https://obsidian.md):
1. **Open folder as vault** → select `antigravity-skills-hub`
2. Press `Cmd+G` (Mac) or `Ctrl+G` (Windows) → **Interactive Graph View**
3. Open `00 - 🧭 Skills Dashboard.md` for the central command dashboard
4. Open `01 - 🗺️ Skills Workflow.canvas` for the visual SDLC workflow map

All 68 skills are interconnected via bidirectional `[[Wikilinks]]` with color-coded stage groupings.

---

## Automated Verification

Verify your installation at any time:

```bash
python3 verify_skills_vault.py
```

The test runner validates:
1. `SKILL.md` readability and UTF-8 encoding across all 68 directories
2. Valid YAML frontmatter and `## 🔗 Connected Skills`
3. 100% parity between local mirror and iCloud Vault
4. Symlink health in `~/.gemini` and `~/.cursor`
5. Zero broken wikilinks or relative paths
6. Visual Canvas coverage
7. Graph view color mappings

---

## Citation

If you use Antigravity Skills Hub in your research, agents, or open-source projects:

```bibtex
@software{jamemm2026antigravity,
  author = {Jamemm},
  title = {Antigravity Skills Hub: Unified 8-Stage SDLC Agentic Skills Ecosystem},
  url = {https://github.com/JameMy0001/antigravity-skills-hub},
  version = {2.2.0},
  year = {2026},
}
```

---

## License

Copyright © 2026 **Jamemm** ([@JameMy0001](https://github.com/JameMy0001))

Licensed under the [MIT License](./LICENSE). Third-party notices and upstream attributions are documented in [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md).

<div align="center">

*Engineered by [Jamemm](https://github.com/JameMy0001) · Star ⭐ this repository if it helps you build better AI agents!*

</div>

<!-- v2.2.0 synchronized: 2026-10-02 -->
