# No-Emoji Minimalism: Technical Reference & CI/CD Guide

This document provides Unicode technical specifications, comparison benchmarks against industry alternatives, CI/CD integration recipes, and linter configuration details.

---

## 1. Industry Benchmark Comparison: Why This Skill is Superior

| Capability | Generic Prompt Rules ("Never use emojis") | Markdownlint (MD026) | Gitlint / Commitlint | Our `no-emoji-minimalism` Skill |
| :--- | :--- | :--- | :--- | :--- |
| **Whitelisted Functional Markers** | ❌ Breaks on `✅` or `❌` in test reports | ❌ Flags all punctuation | ❌ Blocks all or none | ✅ Preserves `[PASS] ✅`, `[FAIL] ❌`, `⚠️`, `🔴🟡🟢`, `⭐` |
| **Multi-Surface Enforcement** | ⚠️ Chat prompt only | ❌ Markdown files only | ❌ Commits only | ✅ 4 Zones: Code, Commits, Headings, Bullets |
| **Automated Auto-Fixer** | ❌ Manual editing required | ⚠️ Limited rules | ❌ Fails without fixing | ✅ `--fix` strips emojis and auto-heals whitespace |
| **Git Pre-Commit & Commit-Msg Hooks** | ❌ None | ⚠️ Staged files only | ⚠️ Commit message only | ✅ Both `--staged` file checks and `--commit-msg` validation |
| **Unicode Cluster Sanitization** | ❌ Leaves orphaned ZWJ / VS-16 | ❌ Leaves invisible bytes | ❌ Raw byte checks | ✅ Cleans full grapheme clusters (ZWJ `\u200d`, VS-16 `\ufe0f`) |
| **Zero Subagent Overhead** | N/A | Local CLI | Local CLI | ✅ Single-Agent Mode with zero token waste |

---

## 2. Unicode Emoji Ranges Reference

The linter flags characters belonging to standard Unicode Emoji and decorative pictograph blocks:

| Block | Range | Description |
| :--- | :--- | :--- |
| **Miscellaneous Symbols & Pictographs** | `U+1F300` - `U+1F5FF` | Icons, objects, weather, entertainment |
| **Emoticons** | `U+1F600` - `U+1F64F` | Faces, emotional expressions |
| **Transport & Map Symbols** | `U+1F680` - `U+1F6FF` | Vehicles, signs, rockets, airplanes |
| **Supplemental Symbols** | `U+1F900` - `U+1F9FF` | Gestures, food, animals |
| **Symbols & Pictographs Extended-A** | `U+1FA00` - `U+1FAFF` | Modern Unicode additions |
| **Miscellaneous Symbols** | `U+2600` - `U+26FF` | Dingbats, warnings, stars, gears, coffee |
| **Dingbats** | `U+2700` - `U+27BF` | Checkmarks, crosses, arrows, ornaments |

---

## 3. Approved Functional Whitelist

The following characters and glyph clusters are explicitly whitelisted because they represent machine-parsable execution or security triage states:

```python
WHITELIST = {
    '✅',  # U+2705 - Verification PASSED
    '❌',  # U+274C - Verification FAILED / Error
    '⚠️',  # U+26A0 + U+FE0F - Warning / Attention Required
    '🔴',  # U+1F534 - Critical Severity (P0)
    '🟡',  # U+1F7E1 - Medium/Warning Severity (P1)
    '🟢',  # U+1F7E2 - Low/Info Severity (P2)
    '⭐',  # U+2B50 - Quantitative Rating / Score
}
```

---

## 4. Git Hooks Configuration

### A. Pre-Commit Hook (`.git/hooks/pre-commit`)
Validates that newly staged files contain zero decorative emojis:

```bash
#!/usr/bin/env bash
python3 Skills/no-emoji-minimalism/scripts/lint_no_emoji.py --staged || {
    echo "Commit rejected: unauthorized decorative emojis detected in staged files."
    echo "Run 'python3 Skills/no-emoji-minimalism/scripts/lint_no_emoji.py --fix .' to clean."
    exit 1
}
```

### B. Commit-Msg Hook (`.git/hooks/commit-msg`)
Validates that the commit message itself adheres to clean Conventional Commits without decorative emoji prefixes:

```bash
#!/usr/bin/env bash
python3 Skills/no-emoji-minimalism/scripts/lint_no_emoji.py --commit-msg "$1" || {
    echo "Commit rejected: unauthorized decorative emojis detected in commit message."
    exit 1
}
```

---

## 5. GitHub Actions CI Integration

Add to `.github/workflows/lint-emojis.yml`:

```yaml
name: Lint Zero Emojis

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  check-emojis:
    name: Verify Clean Typography (No Decorative Emojis)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - name: Run Zero-Emoji Linter
        run: |
          python3 Skills/no-emoji-minimalism/scripts/lint_no_emoji.py --check .
```

<!-- v1.1.0 synchronized: 2026-09-29 -->
