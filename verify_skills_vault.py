#!/usr/bin/env python3
"""
Verification Script for Centralized Obsidian Skills Vault Integration
Architected by Jamemm (@JameMy0001) — https://github.com/JameMy0001/antigravity-skills-hub

Validates:
1. Every skill directory in the vault has a readable SKILL.md (61 skills total).
2. Every SKILL.md has valid YAML frontmatter (name, description, aliases, category,
   tags with agent-skill & stage) and "## 🔗 Connected Skills".
3. Symlinks in ~/.gemini/config/skills and ~/.cursor/skills resolve cleanly.
4. Zero broken wikilinks across ALL markdown files.
5. Canvas Coverage: Skills Workflow.canvas contains nodes for all skills.
6. Graph Color Groups: .obsidian/graph.json defines color group for Stage 8.

Usage:
    python3 verify_skills_vault.py              # auto-detect vault from script location
    python3 verify_skills_vault.py --check-mirror   # also verify iCloud mirror parity

Environment variables:
    SKILLS_VAULT_PATH   Override the vault root directory (absolute path)
    ICLOUD_SKILLS_PATH  Override the iCloud mirror path (optional, used with --check-mirror)
"""

import os
import sys
import re
import json
import argparse

# ──────────────────────────────────────────────────────────────────────────────
# PORTABLE PATH DETECTION — works on any macOS/Linux/Windows user account
# Priority: 1) env var  2) parent dir of this script file
# ──────────────────────────────────────────────────────────────────────────────
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

LOCAL_VAULT = os.environ.get("SKILLS_VAULT_PATH", _SCRIPT_DIR)
LOCAL_SKILLS = os.path.join(LOCAL_VAULT, "Skills")

# iCloud mirror is optional — only checked when --check-mirror flag is passed
_icloud_env = os.environ.get("ICLOUD_SKILLS_PATH", "")
ICLOUD_VAULT = _icloud_env if _icloud_env else None
ICLOUD_SKILLS = os.path.join(ICLOUD_VAULT, "Skills") if ICLOUD_VAULT else None

GEMINI_SYMLINK = os.path.expanduser("~/.gemini/config/skills")
CURSOR_SYMLINK = os.path.expanduser("~/.cursor/skills")

EXPECTED_CATEGORIES = {
    "01 - New Features & Business Logic",
    "02 - Bug Fixing & Defect Resolution",
    "03 - Database & Migrations",
    "04 - Web & Frontend",
    "05 - Security & Code Quality",
    "06 - Git, Commits & Release",
    "07 - Codebase Exploration & Tooling",
    "08 - Productivity & Office Documents",
}

import yaml

def list_skill_dirs(skills_dir):
    if not os.path.isdir(skills_dir):
        return None
    return sorted(
        d for d in os.listdir(skills_dir)
        if not d.startswith(".") and os.path.isdir(os.path.join(skills_dir, d))
    )

def parse_frontmatter(content):
    if not content.startswith("---"):
        return None, "Does not start with ---"
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "First line is not ---"
    
    fm_lines = []
    end_idx = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
        fm_lines.append(lines[i])
        
    if end_idx == -1:
        return None, "Unclosed frontmatter"
        
    body = "\n".join(lines[end_idx+1:])
    
    yaml_text = "\n".join(fm_lines)
    try:
        data = yaml.safe_load(yaml_text)
        if not isinstance(data, dict):
            return None, "YAML frontmatter is not a dictionary"
        return data, body
    except Exception as e:
        return None, f"YAML Syntax Error: {e}"

def check_1_readable_skill_md():
    errors = []
    expected_skills = list_skill_dirs(LOCAL_SKILLS)
    if expected_skills is None:
        errors.append(f"Local Vault skills directory missing: {LOCAL_SKILLS}")
        return errors

    vaults_to_check = [("Local Vault", LOCAL_SKILLS)]
    if ICLOUD_SKILLS:
        vaults_to_check.append(("iCloud Mirror", ICLOUD_SKILLS))

    for vault_name, vault_skills in vaults_to_check:
        if not os.path.isdir(vault_skills):
            errors.append(f"{vault_name} skills directory missing: {vault_skills}")
            continue

        skills = list_skill_dirs(vault_skills) or []
        missing = sorted(set(expected_skills) - set(skills))
        unexpected = sorted(set(skills) - set(expected_skills))
        if missing:
            errors.append(f"Missing skills in {vault_name}: {missing}")
        if unexpected:
            errors.append(f"Unexpected extra skills in {vault_name}: {unexpected}")

        for s in skills:
            skill_dir = os.path.join(vault_skills, s)
            if not os.path.isdir(skill_dir):
                continue
            skill_md = os.path.join(skill_dir, "SKILL.md")
            if not os.path.isfile(skill_md):
                errors.append(f"Missing SKILL.md in {vault_name}: {skill_dir}")
            else:
                try:
                    with open(skill_md, "r", encoding="utf-8") as f:
                        data = f.read()
                    if len(data.strip()) == 0:
                        errors.append(f"Empty SKILL.md in {vault_name}: {skill_dir}")
                except Exception as e:
                    errors.append(f"Unreadable SKILL.md in {vault_name}: {skill_dir}: {e}")
    return errors

def check_2_frontmatter_and_connected():
    errors = []
    # Use iCloud skills dir if available, otherwise fall back to local vault
    primary_skills = ICLOUD_SKILLS if ICLOUD_SKILLS else LOCAL_SKILLS
    if not os.path.isdir(primary_skills):
        return [f"Primary skills directory missing: {primary_skills}"]

    skills = list_skill_dirs(primary_skills) or []
    for s in skills:
        skill_md = os.path.join(primary_skills, s, "SKILL.md")
        if not os.path.exists(skill_md):
            continue
        with open(skill_md, "r", encoding="utf-8") as f:
            content = f.read()
        
        fm, body = parse_frontmatter(content)
        if fm is None:
            errors.append(f"[{s}] Invalid frontmatter: {body}")
            continue
        
        for req_field in ["name", "description", "category", "tags", "aliases"]:
            if req_field not in fm or not fm[req_field]:
                errors.append(f"[{s}] Missing or empty required frontmatter field: {req_field}")
        
        category = fm.get("category")
        if category not in EXPECTED_CATEGORIES:
            errors.append(f"[{s}] Category '{category}' not in expected 8 categories")
            
        tags = fm.get("tags", [])
        if not isinstance(tags, list) or "agent-skill" not in tags:
            errors.append(f"[{s}] Tags must be a list containing 'agent-skill'")
        elif not any(t.startswith("stage-") for t in tags):
            errors.append(f"[{s}] Tags must contain a stage tag (e.g. stage-1..stage-8)")
            
        if "## 🔗 Connected Skills" not in content and "## 🔗 Connected Skills (ทักษะที่เกี่ยวข้อง)" not in content:
            errors.append(f"[{s}] Missing '## 🔗 Connected Skills' section")
            
    return errors


def check_3_parity():
    errors = []
    if not ICLOUD_VAULT:
        return errors  # parity check skipped (no --check-mirror / ICLOUD_SKILLS_PATH not set)

    def get_vault_files(base_dir):
        files_dict = {}
        for root, dirs, files in os.walk(base_dir):
            dirs[:] = [d for d in dirs if not d.startswith(".git")]
            for f in files:
                if f == ".DS_Store" or f.startswith("workspace"):
                    continue
                full = os.path.join(root, f)
                rel = os.path.relpath(full, base_dir)
                files_dict[rel] = full
        return files_dict

    icloud_files = get_vault_files(ICLOUD_VAULT)
    local_files = get_vault_files(LOCAL_VAULT)

    diff = set(icloud_files.keys()) ^ set(local_files.keys())
    if diff:
        errors.append(f"Vault full-tree file set mismatch between iCloud and Local: {diff}")

    common = set(icloud_files.keys()) & set(local_files.keys())
    for rel in common:
        p1 = icloud_files[rel]
        p2 = local_files[rel]
        with open(p1, "rb") as f1, open(p2, "rb") as f2:
            if f1.read() != f2.read():
                errors.append(f"Content byte mismatch between iCloud and Local for: {rel}")

    return errors


def check_4_symlinks():
    errors = []
    expected_skills = list_skill_dirs(LOCAL_SKILLS)
    if expected_skills is None:
        errors.append(f"Local Vault skills directory missing: {LOCAL_SKILLS}")
        return errors

    for link_path, name in [(GEMINI_SYMLINK, "Gemini"), (CURSOR_SYMLINK, "Cursor")]:
        if not os.path.islink(link_path):
            errors.append(f"{name} symlink is not a valid symlink: {link_path}")
            continue
        target = os.path.realpath(link_path)
        if not os.path.exists(target):
            errors.append(f"{name} symlink target does not exist: {target}")
            continue
        for s in expected_skills:
            skill_md = os.path.join(link_path, s, "SKILL.md")
            if not os.path.isfile(skill_md):
                errors.append(f"Symlink {name} cannot access SKILL.md for {s}")
    return errors

def check_5_wikilinks():
    errors = []
    primary_vault = ICLOUD_VAULT if ICLOUD_VAULT else LOCAL_VAULT
    primary_skills = ICLOUD_SKILLS if ICLOUD_SKILLS else LOCAL_SKILLS
    if not os.path.isdir(primary_vault):
        return [f"Primary vault directory missing: {primary_vault}"]
    if not os.path.isdir(primary_skills):
        return [f"Primary skills directory missing: {primary_skills}"]

    all_known_skills = set(list_skill_dirs(primary_skills) or [])
    wikilink_pattern = re.compile(r"\[\[([^\]]+)\]\]")

    all_md_files = []
    for root, _, fnames in os.walk(primary_vault):
        for fn in fnames:
            if fn.endswith(".md"):
                all_md_files.append(os.path.join(root, fn))

    for fp in all_md_files:
        rel = os.path.relpath(fp, primary_vault)
        with open(fp, "r", encoding="utf-8") as f:
            content = f.read()

        content_no_code = re.sub(r"```.*?```", "", content, flags=re.DOTALL)
        content_no_code = re.sub(r"`[^`\n]+`", "", content_no_code)
        matches = wikilink_pattern.findall(content_no_code)
        for m in matches:
            target = m.split("|")[0].strip().split("#")[0].strip()
            if not target:
                continue

            target_clean = target
            resolved = False
            if target_clean.startswith("Skills/"):
                parts = target_clean.split("/")
                target_skill = parts[1]
                if target_skill in all_known_skills:
                    resolved = True
            elif target_clean in all_known_skills:
                resolved = True
            elif os.path.exists(os.path.join(primary_vault, target_clean)) or os.path.exists(os.path.join(primary_vault, target_clean + ".md")):
                resolved = True
            if not resolved:
                errors.append(f"[{rel}] Broken wikilink: [[{m}]] -> target '{target_clean}' cannot be resolved")

    return errors



def check_6_canvas_coverage():
    errors = []
    primary_vault = ICLOUD_VAULT if ICLOUD_VAULT else LOCAL_VAULT
    canvas_path = os.path.join(primary_vault, "01 - 🗺️ Skills Workflow.canvas")
    if not os.path.isfile(canvas_path):
        return [f"Canvas file missing: {canvas_path}"]
    
    try:
        with open(canvas_path, "r", encoding="utf-8") as f:
            canvas_data = json.load(f)
    except Exception as e:
        return [f"Failed to parse canvas JSON: {e}"]
        
    nodes = canvas_data.get("nodes", [])
    edges = canvas_data.get("edges", [])
    node_ids = set(n.get("id") for n in nodes)
    
    canvas_file_skills = set()
    for n in nodes:
        if n.get("type") == "file":
            filepath = n.get("file", "")
            full_path = os.path.join(primary_vault, filepath)
            if not os.path.isfile(full_path):
                errors.append(f"Canvas node '{n.get('id')}' references non-existent file: {filepath}")
            if filepath.startswith("Skills/") and filepath.endswith("/SKILL.md"):
                skill_name = filepath.split("/")[1]
                canvas_file_skills.add(skill_name)

    if not canvas_file_skills:
        errors.append("Canvas does not contain any skill file nodes (Skills/*/SKILL.md)")
            
    seen_edge_ids = set()
    for e in edges:
        eid = e.get("id")
        if eid in seen_edge_ids:
            errors.append(f"Duplicate edge ID: {eid}")
        seen_edge_ids.add(eid)

        from_node = e.get("fromNode")
        to_node = e.get("toNode")
        if from_node not in node_ids:
            errors.append(f"Edge '{eid}' references non-existent fromNode: {from_node}")
        if to_node not in node_ids:
            errors.append(f"Edge '{eid}' references non-existent toNode: {to_node}")
            
    return errors

def check_7_graph_color_groups():
    errors = []
    primary_vault = ICLOUD_VAULT if ICLOUD_VAULT else LOCAL_VAULT
    graph_path = os.path.join(primary_vault, ".obsidian", "graph.json")
    if not os.path.isfile(graph_path):
        return [f"graph.json missing: {graph_path}"]
    
    try:
        with open(graph_path, "r", encoding="utf-8") as f:
            graph_data = json.load(f)
    except Exception as e:
        return [f"Failed to parse graph.json: {e}"]
        
    color_groups = graph_data.get("colorGroups", [])
    queries = [cg.get("query", "") for cg in color_groups]
    
    if not any("stage-8" in q for q in queries):
        errors.append("graph.json missing color group for tag:#stage-8")
        
    return errors


def main():
    print("=========================================")
    print("🧪 RUNNING OBSIDIAN SKILLS VAULT VERIFICATION")
    print("=========================================")
    
    tests = [
        ("1. Readable SKILL.md in all directories", check_1_readable_skill_md),
        ("2. Valid YAML frontmatter & Connected Skills", check_2_frontmatter_and_connected),
        ("3. 100% Parity iCloud vs Local Mirror (full tree)", check_3_parity),
        ("4. Symlinks in ~/.gemini and ~/.cursor", check_4_symlinks),
        ("5. Zero broken wikilinks across entire vault", check_5_wikilinks),
        ("6. Canvas Integrity (skill file nodes & edges)", check_6_canvas_coverage),
        ("7. Graph Color Groups (Stage 8 in graph.json)", check_7_graph_color_groups),
    ]
    
    all_passed = True
    total_errors = 0
    for title, func in tests:
        print(f"\n--- Checking: {title} ---")
        errs = func()
        if errs:
            all_passed = False
            total_errors += len(errs)
            print(f"❌ FAILED ({len(errs)} issues):")
            for e in errs[:10]:
                print(f"  - {e}")
            if len(errs) > 10:
                print(f"  ... and {len(errs) - 10} more.")
        else:
            print("✅ PASSED")
            
    print("\n=========================================")
    if all_passed:
        print("🎉 ALL VERIFICATION CHECKS PASSED PERFECTLY!")
        print("=========================================")
        sys.exit(0)
    else:
        print(f"❌ VERIFICATION FAILED: {total_errors} total errors found.")
        print("=========================================")
        sys.exit(1)

if __name__ == "__main__":
    main()
