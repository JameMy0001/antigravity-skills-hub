#!/usr/bin/env python3
"""
lint_no_emoji.py - Production Zero-Emoji Linter & Auto-Fixer
Author: Jamemm (@JameMy0001)

Scans source code, documentation, and git commits for unauthorized decorative emojis.
Supports checking (--check), automated stripping (--fix), git pre-commit staged scans (--staged),
and commit message validation (--commit-msg) while preserving whitelisted functional status indicators.
"""

import sys
import os
import argparse
import unicodedata
import re
import subprocess

# Whitelist: Functional status indicators, severity triage badges, score stars, and link icons
WHITELIST = {'✅', '❌', '⚠️', '🔴', '🟡', '🟢', '⭐', '🔗'}
WHITELIST_CHARS = {
    '\u2705',  # Check mark
    '\u274c',  # Cross mark
    '\u26a0',  # Warning sign base
    '\U0001f534',  # Red circle
    '\U0001f7e1',  # Yellow circle
    '\U0001f7e2',  # Green circle
    '\u2b50',  # Star base
    '\U0001f517',  # Link icon (for markdown/obsidian backlinks)
    '\ufe0f',  # Variation selector-16
    '\u200d',  # Zero-width joiner
}

# Directories excluded from scans
SKIP_DIRS = {'.git', 'node_modules', '.venv', '__pycache__', '.obsidian', 'dist', 'build', '.tmp'}

# Valid source and documentation extensions
VALID_EXTS = {
    '.py', '.js', '.ts', '.tsx', '.jsx', '.go', '.rs', '.java',
    '.c', '.cpp', '.h', '.hpp', '.sh', '.bash', '.md', '.txt',
    '.yml', '.yaml', '.html', '.css', '.sql', '.json'
}

def is_forbidden_codepoint(code, char):
    """Returns True if the character codepoint is a decorative emoji."""
    if char in WHITELIST_CHARS:
        return False
    # Standard Unicode Emoji blocks
    if 0x1F300 <= code <= 0x1FAFF:
        return True
    # Miscellaneous Symbols & Dingbats (category 'So' - Symbol, other)
    if (0x2600 <= code <= 0x27BF) and unicodedata.category(char) == 'So':
        return True
    return False

def is_forbidden_emoji(char):
    """Returns True if char is forbidden."""
    return is_forbidden_codepoint(ord(char), char)

def scan_text(text):
    """Scans text lines and returns a list of (line_no, col_no, char, line_content)."""
    violations = []
    lines = text.splitlines()
    disabled = False

    for line_no, line in enumerate(lines, 1):
        if 'no-emoji-disable' in line:
            disabled = True
            continue
        if 'no-emoji-enable' in line:
            disabled = False
            continue
        if disabled or 'no-emoji-ignore' in line:
            continue

        i = 0
        n = len(line)
        while i < n:
            matched_whitelist = False
            for wl in WHITELIST:
                if line.startswith(wl, i):
                    i += len(wl)
                    matched_whitelist = True
                    break
            if matched_whitelist:
                continue

            char = line[i]
            code = ord(char)
            if is_forbidden_codepoint(code, char):
                violations.append((line_no, i + 1, char, line.strip()))
                # Skip attached variation selector or ZWJ
                i += 1
                while i < n and (line[i] in {'\ufe0f', '\u200d'} or is_forbidden_codepoint(ord(line[i]), line[i])):
                    i += 1
                continue
            i += 1
    return violations

def scan_file(filepath):
    """Scans a file and returns a list of violations."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            return scan_text(f.read())
    except Exception:
        return []

def strip_forbidden_emojis(text):
    """Strips forbidden emoji clusters and cleans whitespace while preserving whitelisted symbols and respecting disable directives."""
    lines = text.splitlines(keepends=True)
    out_lines = []
    disabled = False
    changed = False

    for line in lines:
        if 'no-emoji-disable' in line:
            disabled = True
            out_lines.append(line)
            continue
        if 'no-emoji-enable' in line:
            disabled = False
            out_lines.append(line)
            continue
        if disabled or 'no-emoji-ignore' in line:
            out_lines.append(line)
            continue

        result = []
        i = 0
        n = len(line)
        line_changed = False

        while i < n:
            matched_whitelist = False
            for wl in WHITELIST:
                if line.startswith(wl, i):
                    result.append(wl)
                    i += len(wl)
                    matched_whitelist = True
                    break
            if matched_whitelist:
                continue

            char = line[i]
            code = ord(char)
            if is_forbidden_codepoint(code, char):
                line_changed = True
                changed = True
                i += 1
                while i < n and (line[i] in {'\ufe0f', '\u200d'} or is_forbidden_codepoint(ord(line[i]), line[i])):
                    i += 1
                if i < n and line[i] == ' ':
                    i += 1
                continue

            result.append(char)
            i += 1

        cleaned_line = ''.join(result)
        if line_changed:
            cleaned_line = re.sub(r'([^\S\r\n]){2,}', ' ', cleaned_line)
            cleaned_line = re.sub(r'(^|\n)(#{1,6}|\-|\*)\s+', r'\1\2 ', cleaned_line)
        out_lines.append(cleaned_line)

    if not changed:
        return text, False

    return ''.join(out_lines), True

def fix_file(filepath):
    """Strips forbidden emojis from file."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        cleaned, changed = strip_forbidden_emojis(content)
        if changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            return True
    except Exception:
        pass
    return False

def check_commit_msg(msg_filepath):
    """Validates git commit message file."""
    try:
        with open(msg_filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        # Filter out git comment lines (# ...)
        content = ''.join([line for line in lines if not line.strip().startswith('#')])
        violations = scan_text(content)
        if violations:
            print("❌ Commit Message Rejected: Decorative emoji detected in commit message!")
            for line_no, col_no, char, line in violations:
                print(f"   Line {line_no}:{col_no} - '{char}' in: {line}")
            print("\nConventional Commits enforce clean text without emojis (e.g. 'feat: ...', 'fix: ...').")
            return False
        return True
    except Exception as e:
        print(f"Error reading commit message file: {e}")
        return False

def get_staged_files():
    """Retrieves list of git staged files."""
    try:
        output = subprocess.check_output(['git', 'diff', '--cached', '--name-only', '--diff-filter=ACM'], text=True)
        return [f.strip() for f in output.splitlines() if f.strip()]
    except Exception:
        return []

import fnmatch

def load_ignore_patterns(root_dir):
    """Loads file ignore patterns from .noemojignore if present."""
    patterns = set()
    ignore_file = os.path.join(root_dir, '.noemojignore')
    if os.path.isfile(ignore_file):
        try:
            with open(ignore_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        patterns.add(line)
        except Exception:
            pass
    return patterns

def is_ignored(rel_path, ignore_patterns):
    """Checks if rel_path matches any ignore pattern."""
    basename = os.path.basename(rel_path)
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(basename, pattern):
            return True
    return False

def main():
    parser = argparse.ArgumentParser(description="Zero-Emoji Linter & Auto-Fixer")
    parser.add_argument("path", nargs="?", default=".", help="File or directory to scan")
    parser.add_argument("--check", action="store_true", default=False, help="Check and report violations")
    parser.add_argument("--fix", action="store_true", default=False, help="Automatically strip unauthorized emojis from files")
    parser.add_argument("--staged", action="store_true", default=False, help="Scan only git staged files")
    parser.add_argument("--commit-msg", metavar="MSG_FILE", help="Validate a git commit message file (for commit-msg hook)")
    args = parser.parse_args()

    # Commit message validation mode
    if args.commit_msg:
        if check_commit_msg(args.commit_msg):
            print("✅ Commit Message Clean: No forbidden emojis.")
            sys.exit(0)
        else:
            sys.exit(1)

    # Determine files to scan
    if args.staged:
        raw_files = get_staged_files()
        target_path = os.getcwd()
        ignore_patterns = load_ignore_patterns(target_path)
        files_to_scan = [
            f for f in raw_files
            if any(f.endswith(ext) for ext in VALID_EXTS) and os.path.isfile(f) and not is_ignored(f, ignore_patterns)
        ]
    else:
        target_path = os.path.abspath(args.path)
        ignore_patterns = load_ignore_patterns(target_path if os.path.isdir(target_path) else os.path.dirname(target_path))
        if os.path.isfile(target_path):
            files_to_scan = [target_path] if not is_ignored(os.path.basename(target_path), ignore_patterns) else []
        else:
            files_to_scan = []
            for root, dirs, files in os.walk(target_path):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not is_ignored(d, ignore_patterns)]
                for f in files:
                    if any(f.endswith(ext) for ext in VALID_EXTS):
                        rel_path = os.path.relpath(os.path.join(root, f), target_path)
                        if not is_ignored(rel_path, ignore_patterns):
                            files_to_scan.append(os.path.join(root, f))

    total_files = len(files_to_scan)
    total_violations = 0
    fixed_files = 0

    for filepath in files_to_scan:
        violations = scan_file(filepath)
        if violations:
            total_violations += len(violations)
            rel_path = os.path.relpath(filepath, target_path) if os.path.isabs(filepath) else filepath
            for line_no, col_no, char, line in violations:
                print(f"[FORBIDDEN EMOJI] {rel_path}:{line_no}:{col_no} - '{char}' in: {line}")

            if args.fix:
                if fix_file(filepath):
                    fixed_files += 1
                    print(f"  --> Stripped unauthorized emojis from {rel_path}")

    print("\n" + "=" * 50)
    print(f"Scanned {total_files} files.")
    if total_violations == 0:
        print("✅ Clean: Zero forbidden emojis detected!")
        sys.exit(0)
    else:
        if args.fix:
            print(f"Fixed {fixed_files} files with {total_violations} unauthorized emojis removed.")
            sys.exit(0)
        else:
            print(f"❌ Violation: Found {total_violations} forbidden decorative emojis.")
            print("Run with '--fix' to automatically strip them.")
            sys.exit(1)

if __name__ == "__main__":
    main()
