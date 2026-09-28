# Contributing to Antigravity Skills Hub

Welcome! We are thrilled that you want to contribute to the **Antigravity Skills Hub**. This centralized ecosystem provides production-grade, interconnected skills for AI coding agents across **Google Antigravity**, **Cursor IDE**, and **Claude Code**.

---

## 🏗️ Architecture & Philosophy

All skills in this vault adhere to four core architectural principles:

1. **8-Stage SDLC Lifecycle**: Every skill must belong to one of the 8 canonical stages:
   - `01 - New Features & Business Logic`
   - `02 - Bug Fixing & Defect Resolution`
   - `03 - Database & Migrations`
   - `04 - Web & Frontend`
   - `05 - Security & Code Quality`
   - `06 - Git, Commits & Release`
   - `07 - Codebase Exploration & Tooling`
   - `08 - Productivity & Office Documents`
2. **Single-Agent First (Token-Efficient)**: Skills must NOT command agents to spawn background subagents automatically. The primary agent executes tasks directly.
3. **On-Demand Confirmation**: Heavy workflows must recommend confirmation before loading.
4. **Bidirectional Knowledge Graph**: Every skill must connect to adjacent skills using Obsidian `[[Wikilinks]]`.

---

## 📦 How to Add a New Skill

1. **Create the Skill Directory**:
   ```bash
   mkdir -p Skills/<your-skill-name>
   ```

2. **Write `SKILL.md`**:
   Every skill must include valid YAML frontmatter following this exact schema:
   ```markdown
   ---
   name: <your-skill-name>
   description: <Clear 1-2 sentence description stating what it does and when to use it>
   aliases:
     - <alias-1>
     - <alias-2>
   category: "<One of the 8 SDLC stages>"
   tags:
     - agent-skill
     - <domain-tag>
     - stage-<1-8>
   ---

   # <Skill Title>

   <Detailed instructions, code patterns, and execution guidelines>

   ---
   ## 🔗 Connected Skills (ทักษะที่เกี่ยวข้อง)
   - [[Skills/<related-skill-1>/SKILL|<related-skill-1>]] — Description of connection
   - [[Skills/<related-skill-2>/SKILL|<related-skill-2>]] — Description of connection
   ```

3. **Verify Locally Before Submitting**:
   Run the verification engine to ensure no broken links or syntax errors exist:
   ```bash
   python3 verify_skills_vault.py
   ```

4. **Submit a Pull Request**:
   - Push your branch to GitHub and open a Pull Request using the PR template.
   - Ensure the GitHub Actions CI passes completely.

Thank you for helping build the premier AI agent skills ecosystem!

<!-- v1.1.0 synchronized: 2026-09-29 -->
