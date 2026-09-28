# Agent Skill Examples & Patterns

This document provides real-world reference implementations demonstrating the three degrees of freedom.

---

## Example 1: High Degree of Freedom (Heuristic & Principle-Based)

```markdown
---
name: code-review-standards
description: Review pull requests for architectural integrity, error resilience, and code style. Trigger when reviewing diffs or PRs.
category: "05 - Security & Code Quality"
tags: [agent-skill, review, quality, stage-5]
aliases: [code-review, pr-review]
---

# Code Review Standards

## Principles
1. Verify intent before checking formatting.
2. Flag architectural bottlenecks, security vulnerabilities, and missing error handlers first.
3. Suggest concrete code replacements rather than abstract critique.

## Review Triage
- 🔴 **Critical**: Security breach, data loss, regression bug, breaking API change without versioning.
- 🟡 **Suggestion**: Refactoring opportunity, missing test case, suboptimal complexity.
- 🟢 **Nitpick**: Minor stylistic suggestion, naming improvement (prefix with `Nit:`).
```

---

## Example 2: Medium Degree of Freedom (Template & Step-by-Step)

```markdown
---
name: api-endpoint-scaffold
description: Scaffold production-ready REST API endpoints with validation and error handling. Trigger when creating new API routes.
category: "01 - New Features & Business Logic"
tags: [agent-skill, api, backend, stage-1]
aliases: [scaffold-api, new-endpoint]
---

# API Endpoint Scaffold

## Workflow Steps
1. Define input DTO and output DTO with validation schemas (Pydantic / Zod).
2. Create service layer method with transaction isolation.
3. Implement HTTP controller with standard status codes (201 for POST, 204 for DELETE).
4. Register OpenAPI metadata and error responses (400, 401, 403, 404, 500).
5. Write integration test covering happy path and boundary errors.
```

---

## Example 3: Low Degree of Freedom (Script & Deterministic Tooling)

```markdown
---
name: database-migrate-verify
description: Run and verify reversible schema migrations with zero downtime. Trigger when modifying database schemas.
category: "03 - Database & Migrations"
tags: [agent-skill, database, migrations, stage-3]
aliases: [db-migrate, run-migrations]
---

# Database Migration & Verification

## Deterministic Execution
Always run the validation script before applying migrations:

```bash
python3 scripts/verify_migration.py --dry-run
```

If dry run succeeds:
```bash
python3 scripts/apply_migration.py
```
```
