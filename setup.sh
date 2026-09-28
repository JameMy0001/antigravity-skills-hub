#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# antigravity-skills-hub — setup.sh
# One-command modular installer for macOS and Linux
# Architected by Jamemm (@JameMy0001)
# https://github.com/JameMy0001/antigravity-skills-hub
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()   { echo -e "${CYAN}[setup]${RESET} $*"; }
ok()    { echo -e "${GREEN}[  ✅  ]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[ WARN ]${RESET} $*"; }
error() { echo -e "${RED}[ ERR  ]${RESET} $*" >&2; exit 1; }

# ── Detect vault root ────────────────────────────────────────────────────────
VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$VAULT_DIR/Skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
    error "Skills directory not found at: $SKILLS_DIR\n  Make sure you cloned the full repository."
fi

SKILL_COUNT=$(ls "$SKILLS_DIR" | wc -l | tr -d ' ')

# ── Parse Arguments ──────────────────────────────────────────────────────────
MODE="all"
TARGET_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list|-l)
            MODE="list"
            shift
            ;;
        --skill|-s)
            MODE="single"
            TARGET_ARG="${2:-}"
            if [[ -z "$TARGET_ARG" ]]; then error "Missing argument for --skill <name>"; fi
            shift 2
            ;;
        --stage)
            MODE="stage"
            TARGET_ARG="${2:-}"
            if [[ -z "$TARGET_ARG" ]]; then error "Missing argument for --stage <1-8>"; fi
            shift 2
            ;;
        --help|-h)
            echo -e "${BOLD}Antigravity Skills Hub Installer${RESET}"
            echo "Usage: ./setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (none)              Install and link all $SKILL_COUNT skills (Default)"
            echo "  --list, -l          List all available skills organized by SDLC stage"
            echo "  --skill, -s <name>  Link only a specific skill into agent directories"
            echo "  --stage <1-8>       Link only skills belonging to a specific SDLC stage"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            warn "Unknown option: $1 (ignoring)"
            shift
            ;;
    esac
done

# ── Mode: List ───────────────────────────────────────────────────────────────
if [[ "$MODE" == "list" ]]; then
    echo -e "${BOLD}${BLUE}⚡ Antigravity Skills Hub — Catalog (${SKILL_COUNT} Skills)${RESET}\n"
    python3 -c "
import os, yaml
s_dir = '$SKILLS_DIR'
skills = sorted([d for d in os.listdir(s_dir) if os.path.isdir(os.path.join(s_dir, d)) and not d.startswith('.')])
by_cat = {}
for s in skills:
    f = os.path.join(s_dir, s, 'SKILL.md')
    cat = 'Uncategorized'
    if os.path.exists(f):
        with open(f) as fh:
            parts = fh.read().split('---', 2)
            if len(parts) >= 3:
                try:
                    data = yaml.safe_load(parts[1])
                    cat = data.get('category', 'Uncategorized')
                except: pass
    by_cat.setdefault(cat, []).append(s)

for c in sorted(by_cat.keys()):
    print(f'\033[1m[{c}]\033[0m ({len(by_cat[c])} skills)')
    for s in by_cat[c]:
        print(f'  - {s}')
    print()
"
    exit 0
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ⚡ Antigravity Skills Hub — Setup Installer"
echo "  By Jamemm (@JameMy0001)"
echo "  https://github.com/JameMy0001/antigravity-skills-hub"
echo -e "${RESET}"

log "Vault root: $VAULT_DIR"
log "Skills dir: $SKILLS_DIR"
log "Total skills: $SKILL_COUNT"

# ── Git configuration for Thai/Emoji filenames ────────────────────────────────
log "Configuring git for Unicode filenames (Thai + Emoji)..."
git -C "$VAULT_DIR" config core.precomposeunicode true 2>/dev/null || true
git -C "$VAULT_DIR" config core.quotepath false 2>/dev/null || true
ok "Git Unicode config applied"

# ── Selective Skill Linking Helper ───────────────────────────────────────────
link_target_dir() {
    local target_base="$1"
    local agent_name="$2"

    mkdir -p "$target_base"
    
    if [[ "$MODE" == "all" ]]; then
        log "Setting up $agent_name symlink (All $SKILL_COUNT skills) → $target_base"
        if [[ -L "$target_base" ]]; then
            warn "Symlink already exists at $target_base (skipping)"
        elif [[ -d "$target_base" ]]; then
            warn "Directory exists at $target_base — backing up to ${target_base}.backup"
            mv "$target_base" "${target_base}.backup"
            ln -s "$SKILLS_DIR" "$target_base"
            ok "Symlink created → $target_base"
        else
            mkdir -p "$(dirname "$target_base")"
            ln -s "$SKILLS_DIR" "$target_base"
            ok "Symlink created → $target_base"
        fi
    elif [[ "$MODE" == "single" ]]; then
        local src_skill="$SKILLS_DIR/$TARGET_ARG"
        if [[ ! -d "$src_skill" ]]; then
            error "Skill '$TARGET_ARG' not found in $SKILLS_DIR"
        fi
        log "Linking single skill '$TARGET_ARG' into $agent_name..."
        mkdir -p "$target_base"
        ln -sfn "$src_skill" "$target_base/$TARGET_ARG"
        ok "Skill '$TARGET_ARG' linked → $target_base/$TARGET_ARG"
    elif [[ "$MODE" == "stage" ]]; then
        log "Linking Stage $TARGET_ARG skills into $agent_name..."
        mkdir -p "$target_base"
        python3 -c "
import os, yaml
s_dir = '$SKILLS_DIR'
target = '$target_base'
stage_num = '$TARGET_ARG'
for s in sorted(os.listdir(s_dir)):
    f = os.path.join(s_dir, s, 'SKILL.md')
    if os.path.exists(f):
        with open(f) as fh:
            parts = fh.read().split('---', 2)
            if len(parts) >= 3:
                try:
                    data = yaml.safe_load(parts[1])
                    tags = data.get('tags', [])
                    if f'stage-{stage_num}' in tags:
                        dest = os.path.join(target, s)
                        if os.path.islink(dest) or os.path.exists(dest):
                            try: os.unlink(dest)
                            except: pass
                        os.symlink(os.path.join(s_dir, s), dest)
                        print(f'  [Linked] {s}')
                except: pass
"
        ok "Stage $TARGET_ARG skills linked"
    fi
}

link_target_dir "$HOME/.gemini/config/skills" "Google Antigravity"
link_target_dir "$HOME/.cursor/skills" "Cursor IDE"

# ── Python dependencies ────────────────────────────────────────────────────────
log "Installing Python dependencies..."

if command -v uv &>/dev/null; then
    log "Using uv (fast Python package manager)"
    uv pip install -r "$VAULT_DIR/requirements.txt" && ok "Dependencies installed via uv"
elif command -v pip3 &>/dev/null; then
    log "Using pip3"
    pip3 install -r "$VAULT_DIR/requirements.txt" && ok "Dependencies installed via pip3"
elif command -v pip &>/dev/null; then
    log "Using pip"
    pip install -r "$VAULT_DIR/requirements.txt" && ok "Dependencies installed via pip"
else
    warn "No pip or uv found. Install Python 3.9+ and run: pip install -r requirements.txt"
fi

# ── Verification ──────────────────────────────────────────────────────────────
echo ""
log "Running vault verification..."
if python3 "$VAULT_DIR/verify_skills_vault.py"; then
    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${GREEN}  ✅ All $SKILL_COUNT skills installed and verified!${RESET}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "  🎯 Google Antigravity: ready at ${CYAN}~/.gemini/config/skills${RESET}"
    echo -e "  🎯 Cursor IDE:         ready at ${CYAN}~/.cursor/skills${RESET}"
    echo ""
    echo -e "  📖 Open Obsidian → Vault → '$(basename "$VAULT_DIR")' for Graph View"
    echo -e "  📚 README: ${CYAN}$VAULT_DIR/README.md${RESET}"
    echo ""
else
    warn "Verification completed with warnings. See output above for details."
fi
