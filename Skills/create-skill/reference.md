# Agent Skill Specification & Reference Manual

This document provides the technical reference specification for Agent Skills across Antigravity, Cursor, and Obsidian-managed skill vaults.

---

## 1. Directory Structure

A standardized Agent Skill follows this layout:

```
Skills/<skill-name>/
├── SKILL.md             # (Required) Core skill definition and workflow instructions
├── reference.md         # (Optional) Deep reference, full API specifications, or syntax details
├── examples.md          # (Optional) Extended usage examples, prompt sequences, edge cases
├── scripts/             # (Optional) Executable automation scripts (Python, Bash, Node.js)
│   └── run.py
├── templates/           # (Optional) Boilerplate or code generation templates
└── tests/               # (Optional) Automated verification tests for skill scripts
```

---

## 2. YAML Frontmatter Specification

Every `SKILL.md` must begin with valid YAML frontmatter fenced by `---`:

| Field | Type | Required | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `string` | **Yes** | Lowercase kebab-case unique identifier | `name: tdd-workflow` |
| `description` | `string` | **Yes** | 1-2 sentence trigger instructions detailing WHAT it does and WHEN to trigger | `description: "Enforces test-driven development..."` |
| `category` | `string` | **Yes** | SDLC stage category (01-08) | `category: "01 - New Features & Business Logic"` |
| `tags` | `list` | **Yes** | Metadata tags including `agent-skill` and stage | `tags: [agent-skill, testing, tdd, stage-1]` |
| `aliases` | `list` | Recommended | Alternative keywords and triggers for search and autodispatch | `aliases: [tdd, test-driven-development]` |

### Example Frontmatter

```yaml
---
name: tdd-workflow
description: Enforces test-driven development with 80%+ coverage across unit, integration, and E2E tests. Trigger when creating features, fixing bugs, or refactoring.
category: "01 - New Features & Business Logic"
tags:
  - agent-skill
  - testing
  - tdd
  - stage-1
aliases:
  - tdd
  - test-driven-development
---
```

---

## 3. Degrees of Freedom Taxonomy

Match the instruction rigidity to the task's fragility:

| Level | Freedom | Best For | Typical Contents |
| :--- | :--- | :--- | :--- |
| **High** | AI decides implementation details | Creative writing, code review, conceptual brainstorming | Principles, quality heuristics, anti-patterns |
| **Medium** | AI follows standard template with flexibility | API design, documentation, test suites | Step-by-step checklists, component templates, naming rules |
| **Low** | AI must execute exact deterministic sequence | Database migrations, cryptographic operations, release tagging | Executable CLI scripts, rigid bash one-liners, zero deviation |

---

## 4. Progressive Disclosure Guidelines

1. **Keep `SKILL.md` concise (< 500 lines)**: The primary agent loads `SKILL.md` into active context. Long files waste tokens and degrade reasoning.
2. **One-level deep references**: Only link from `SKILL.md` directly to `reference.md` or scripts. Never create multi-hop reference chains (`A -> B -> C`).
3. **Execution Scripts**: For repetitive operations exceeding 10 lines of code, write an executable Python or Bash script in `scripts/` instead of describing the code in text.
