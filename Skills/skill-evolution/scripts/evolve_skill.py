#!/usr/bin/env python3
"""
Curated Skill Evolution & Anti-Bloat Engine CLI
Automates telemetry logging, rule-of-10 enforcement, and anti-bloat audits.
"""

import sys
import os
import re
import argparse
import datetime
from typing import Dict, List, Optional, Tuple

SCRIPT_REAL_PATH = os.path.realpath(__file__)
VAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(SCRIPT_REAL_PATH), "..", "..", ".."))
LEDGER_PATH = os.path.join(VAULT_ROOT, "00 - 📜 Skills Execution Ledger.md")
SKILLS_DIR = os.path.join(VAULT_ROOT, "Skills")

MAX_PATTERNS_PER_SKILL = 10
MAX_PATTERN_TOKENS = 250  # ~1000 characters


def ensure_ledger_exists():
    """Initializes the execution ledger if it doesn't already exist."""
    if not os.path.exists(LEDGER_PATH):
        header = """---
aliases:
  - Skills Execution Ledger
  - Execution History
  - Agent Telemetry
tags:
  - ledger
  - telemetry
  - agent-audit
---

# 📜 Skills Execution Ledger

สมุดบันทึกประวัติการเรียกใช้และผลการปฏิบัติงานของ Agent Skills อย่างเป็นระบบ
ช่วยให้ติดตามการทำงาน วิเคราะห์อัตราความสำเร็จ และตรวจจับข้อค้นพบใหม่โดยไม่ทำให้ไฟล์สกิลบวม

---

## 📊 Execution History

| Timestamp | Task / Objective | Skills Applied | Status | Key Artifacts | Distilled Insight |
| :--- | :--- | :--- | :---: | :--- | :--- |
"""
        with open(LEDGER_PATH, "w", encoding="utf-8") as f:
            f.write(header)


def cmd_record(task: str, skills: str, status: str, artifacts: str, insight: str):
    """Appends an execution event row to the centralized ledger."""
    ensure_ledger_exists()
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    status_badge = f"`[{status.upper()}]`" if status.upper() in ["PASS", "FAIL", "WARN", "OK"] else f"`[{status}]`"
    clean_task = task.replace("|", "-").replace("\n", " ").strip()
    clean_skills = skills.replace("|", "-").strip()
    clean_artifacts = artifacts.replace("|", "-").strip() if artifacts else "-"
    clean_insight = insight.replace("|", "-").replace("\n", " ").strip() if insight else "-"

    row = f"| {ts} | {clean_task} | {clean_skills} | {status_badge} | {clean_artifacts} | {clean_insight} |\n"

    with open(LEDGER_PATH, "a", encoding="utf-8") as f:
        f.write(row)
    print(f"[OK] Execution logged to ledger: {ts} - {clean_skills}")


def parse_patterns(skill_path: str) -> List[Dict[str, str]]:
    """Extracts existing learned patterns from SKILL.md or learned_patterns.md."""
    target_file = os.path.join(skill_path, "learned_patterns.md")
    if not os.path.exists(target_file):
        target_file = os.path.join(skill_path, "SKILL.md")

    if not os.path.exists(target_file):
        return []

    with open(target_file, "r", encoding="utf-8") as f:
        content = f.read()

    patterns = []
    matches = re.finditer(r"### Pattern #(\d+):\s*(.+?)\n-\s*\*\*Condition\*\*:\s*(.+?)\n-\s*\*\*Action\*\*:\s*(.+?)\n-\s*\*\*Avoid\*\*:\s*(.+?)(?=\n###|\n##|\Z)", content, re.DOTALL)
    for m in matches:
        patterns.append({
            "id": int(m.group(1)),
            "title": m.group(2).strip(),
            "condition": m.group(3).strip(),
            "action": m.group(4).strip(),
            "avoid": m.group(5).strip()
        })
    return patterns


def cmd_add_pattern(skill_name: str, title: str, condition: str, action: str, avoid: str):
    """Adds or merges a new heuristic rule into the skill, respecting the Rule of 10."""
    skill_dir = os.path.join(SKILLS_DIR, skill_name)
    if not os.path.exists(skill_dir):
        print(f"[FAIL] Skill '{skill_name}' does not exist at {skill_dir}", file=sys.stderr)
        sys.exit(1)

    patterns_file = os.path.join(skill_dir, "learned_patterns.md")
    existing_patterns = parse_patterns(skill_dir)

    # Check for deduplication
    for p in existing_patterns:
        if p["title"].lower() == title.lower() or (condition.lower() in p["condition"].lower()):
            print(f"[INFO] Pattern overlaps with existing Pattern #{p['id']}: '{p['title']}'. Updating action/avoid...")
            p["action"] = action
            p["avoid"] = avoid
            save_patterns(skill_dir, existing_patterns)
            print(f"[OK] Pattern #{p['id']} consolidated and updated.")
            return

    # Enforce Hard-Cap Rule of 10
    if len(existing_patterns) >= MAX_PATTERNS_PER_SKILL:
        print(f"[WARN] Skill '{skill_name}' reached maximum limit ({MAX_PATTERNS_PER_SKILL} patterns).")
        print(f"[INFO] Merging oldest pattern #1 with incoming rule...")
        existing_patterns.pop(0)

    next_id = max([p["id"] for p in existing_patterns], default=0) + 1
    new_pat = {
        "id": next_id,
        "title": title.strip(),
        "condition": condition.strip(),
        "action": action.strip(),
        "avoid": avoid.strip()
    }
    existing_patterns.append(new_pat)
    save_patterns(skill_dir, existing_patterns)
    print(f"[OK] Added Pattern #{next_id} to '{skill_name}' (Total active rules: {len(existing_patterns)}/{MAX_PATTERNS_PER_SKILL})")


def save_patterns(skill_dir: str, patterns: List[Dict[str, str]]):
    """Writes patterns cleanly formatted into learned_patterns.md."""
    patterns_file = os.path.join(skill_dir, "learned_patterns.md")
    lines = [
        "## Learned Patterns & Edge Cases",
        "",
        "> High-density heuristics distilled from verified production execution.",
        f"> Hard-Cap: Max {MAX_PATTERNS_PER_SKILL} rules. Clean, zero-bloat standard.",
        ""
    ]
    for p in patterns:
        lines.append(f"### Pattern #{p['id']}: {p['title']}")
        lines.append(f"- **Condition**: {p['condition']}")
        lines.append(f"- **Action**: {p['action']}")
        lines.append(f"- **Avoid**: {p['avoid']}")
        lines.append("")

    with open(patterns_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def cmd_audit():
    """Scans all vault skills to ensure zero prompt bloat and clean rule counts."""
    skills = [d for d in os.listdir(SKILLS_DIR) if os.path.isdir(os.path.join(SKILLS_DIR, d)) and not d.startswith(".")]
    print(f"Auditing {len(skills)} skills for anti-bloat compliance...")
    bloated = []
    clean_count = 0

    for s in skills:
        s_path = os.path.join(SKILLS_DIR, s)
        pats = parse_patterns(s_path)
        if len(pats) > MAX_PATTERNS_PER_SKILL:
            bloated.append((s, len(pats)))
        else:
            clean_count += 1

    if bloated:
        print(f"[WARN] Found {len(bloated)} bloated skills exceeding {MAX_PATTERNS_PER_SKILL} patterns:")
        for s, count in bloated:
            print(f"  - {s}: {count} patterns")
    else:
        print(f"[PASS] 100% of skills compliant! Zero bloated skills. (Total clean: {clean_count})")


def main():
    parser = argparse.ArgumentParser(description="Skill Evolution & Anti-Bloat CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # record
    p_rec = subparsers.add_parser("record", help="Log execution to ledger")
    p_rec.add_argument("--task", required=True, help="Task description")
    p_rec.add_argument("--skills", required=True, help="Skills used")
    p_rec.add_argument("--status", default="PASS", help="Execution status (PASS/FAIL)")
    p_rec.add_argument("--artifacts", default="-", help="Key files/artifacts")
    p_rec.add_argument("--insight", default="-", help="Key distilled insight")

    # add-pattern
    p_add = subparsers.add_parser("add-pattern", help="Add a curated heuristic rule")
    p_add.add_argument("--skill", required=True, help="Target skill name")
    p_add.add_argument("--title", required=True, help="Short pattern title")
    p_add.add_argument("--condition", required=True, help="Trigger condition")
    p_add.add_argument("--action", required=True, help="Correct action")
    p_add.add_argument("--avoid", required=True, help="Naive mistake to avoid")

    # audit
    subparsers.add_parser("audit", help="Audit all skills for bloat compliance")

    args = parser.parse_args()

    if args.command == "record":
        cmd_record(args.task, args.skills, args.status, args.artifacts, args.insight)
    elif args.command == "add-pattern":
        cmd_add_pattern(args.skill, args.title, args.condition, args.action, args.avoid)
    elif args.command == "audit":
        cmd_audit()


if __name__ == "__main__":
    main()
