# Reddit Showcase Post: Antigravity Skills Hub v2.2.0

Recommended Subreddits:
- `r/ObsidianMD` (Title: "I turned my Obsidian Vault into a Living AI Agent OS with 68 Skills, Visual Canvas, and Auto-Evolution")
- `r/Cursor` (Title: "Showcase: Centralized Agent Skills Hub for Cursor & Antigravity (Saves 95%+ Tokens with Zero-Bloat Evolution)")
- `r/LocalLLaMA` (Title: "Open Source Agentic Skills Hub: 68 Standardized Skills, 8-Stage SDLC, and 4-Tier Anti-Bloat Heuristic Engine")

---

## Post Title:
**I turned my Obsidian Vault into a Living AI Agent OS with 68 Skills, Visual Canvas, and Auto-Evolution**

## Post Body:

Hey everyone,

Over the past few months of working with autonomous AI coding agents (Cursor Composer, Google Antigravity, Claude Code, and terminal harnesses), I ran into two major friction points that almost every agent engineer hits:

1. **System Prompt Bloat**: Stuffing dozens of coding guidelines, styling rules, and database conventions into global prompt files quickly blows through context limits and degrades model reasoning.
2. **Skill Rot & Fragmentation**: Keeping skills in sync across different tools (Cursor in `~/.cursor`, Antigravity in `~/.gemini`, Claude in `~/.claude`) meant duplicating Markdown files and constantly dealing with out-of-date instructions.

To solve this, I engineered **Antigravity Skills Hub** ([GitHub Repo](https://github.com/JameMy0001/antigravity-skills-hub) | [Live Web Showcase](https://jamemy0001.github.io/antigravity-skills-hub/)).

Here is how the architecture works and why it changed how I develop:

### 1. The Obsidian Knowledge Graph as the Agent Brain
Instead of flat markdown files, all 68 skills are maintained as interconnected nodes inside an Obsidian vault. 
- Every skill has standardized YAML frontmatter and bidirectional `[[Wikilinks]]`.
- Opening the vault in Obsidian provides a visual interactive Canvas (`01 - 🗺️ Skills Workflow.canvas`) and Graph View showing the entire 8-stage software development lifecycle (Features -> Debugging -> Database -> Web/Frontend -> Security -> Git/Release -> Orchestration -> Publication).

### 2. Multi-Agent Symlinking (Single Source of Truth)
Using a modular installer (`./setup.sh`), the skills directory is symlinked directly into:
- Google Antigravity (`~/.gemini/config/skills`)
- Cursor IDE (`~/.cursor/skills`)
- Claude Code (`~/.claude/skills`)

Any edit made in Obsidian—or via mobile iCloud sync—is immediately reflected across all agent environments with zero manual copying.

### 3. Curated Skill Evolution Engine (CSEE)
One common feature request was: *"Can the agent get smarter as you use it without accumulating garbage?"*
We built `evolve-skill`, an automated pipeline with a strict **4-Tier Anti-Bloat Filtration Gate**:
- **Ephemerality Gate**: Drops session-specific fixes and temporary paths.
- **Deduplication Gate**: Merges overlapping heuristics semantically.
- **Hard-Cap Rule of 10**: Enforces a strict ceiling of max 10 rules per skill (pruning obsolete heuristics when better ones arrive).
- **Token Budget Gate**: Strictly restricts each rule to under 250 tokens.

Execution telemetry is automatically logged in `00 - 📜 Skills Execution Ledger.md`, and distilled heuristics live in `learned_patterns.md`.

### 4. Native macOS Computer Use (CUA) Subsystem
For agents that interact with desktop applications:
- Instead of slow 3-5 second screenshot OCR cycles, we built a native Swift Accessibility scanner (`ax-scanner`) that queries the macOS Accessibility tree in 5-10ms.
- A native Cocoa floating HUD (`computer-use-hud`) displays active status and boundary markers over the screen during automation.

### 5. Open Source & Zero-Dependency Setup
The entire repository is open source under MIT:
```bash
git clone https://github.com/JameMy0001/antigravity-skills-hub.git
cd antigravity-skills-hub && ./setup.sh
```

You can install all 68 skills, or selectively link by SDLC stage (e.g. `./setup.sh --stage 4` for frontend craft) or single skill (`./setup.sh --skill claude-design`).

Check it out on GitHub: https://github.com/JameMy0001/antigravity-skills-hub
Interactive web catalog: https://jamemy0001.github.io/antigravity-skills-hub/

Feedback and skill contributions are welcome!
