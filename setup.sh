#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# antigravity-skills-hub — setup.sh
# One-command installer for macOS and Linux
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

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ⚡ Antigravity Skills Hub — Setup Installer"
echo "  By Jamemm (@JameMy0001)"
echo "  https://github.com/JameMy0001/antigravity-skills-hub"
echo -e "${RESET}"

# ── Detect vault root (the directory this script lives in) ───────────────────
VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$VAULT_DIR/Skills"

log "Vault root: $VAULT_DIR"
log "Skills dir: $SKILLS_DIR"

if [[ ! -d "$SKILLS_DIR" ]]; then
    error "Skills directory not found at: $SKILLS_DIR\n  Make sure you cloned the full repository."
fi

SKILL_COUNT=$(ls "$SKILLS_DIR" | wc -l | tr -d ' ')
log "Found $SKILL_COUNT skills in vault"

backup_path_if_exists() {
    local target_path="$1"
    local backup_path="${target_path}.backup"
    if [[ -e "$backup_path" || -L "$backup_path" ]]; then
        backup_path="${backup_path}.$(date +%s)"
    fi
    mv "$target_path" "$backup_path"
    warn "Backed up existing path to $backup_path"
}

ensure_skills_symlink() {
    local link_path="$1"
    local platform_name="$2"

    mkdir -p "$(dirname "$link_path")"

    if [[ -L "$link_path" ]]; then
        local resolved_target
        resolved_target="$(realpath "$link_path" 2>/dev/null || true)"
        if [[ "$resolved_target" == "$SKILLS_DIR" ]]; then
            ok "${platform_name} symlink already correct → $link_path"
            return
        fi
        warn "${platform_name} symlink points to wrong target (${resolved_target:-unresolved}) — replacing"
        backup_path_if_exists "$link_path"
    elif [[ -e "$link_path" ]]; then
        warn "Path exists at $link_path and is not a symlink — replacing"
        backup_path_if_exists "$link_path"
    fi

    ln -s "$SKILLS_DIR" "$link_path"
    ok "Symlink created → $link_path"
}

# ── Git configuration for Thai/Emoji filenames ────────────────────────────────
log "Configuring git for Unicode filenames (Thai + Emoji)..."
git -C "$VAULT_DIR" config core.precomposeunicode true 2>/dev/null || warn "Not a git repo (skipping git config)"
git -C "$VAULT_DIR" config core.quotepath false 2>/dev/null || true
ok "Git Unicode config applied"

# ── Symlink: Google Antigravity ───────────────────────────────────────────────
ANTIGRAVITY_SKILLS="$HOME/.gemini/config/skills"
log "Setting up Google Antigravity symlink → $ANTIGRAVITY_SKILLS"
ensure_skills_symlink "$ANTIGRAVITY_SKILLS" "Google Antigravity"

# ── Symlink: Cursor IDE ────────────────────────────────────────────────────────
CURSOR_SKILLS="$HOME/.cursor/skills"
log "Setting up Cursor IDE symlink → $CURSOR_SKILLS"
ensure_skills_symlink "$CURSOR_SKILLS" "Cursor IDE"

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

# ── Playwright browser binaries ───────────────────────────────────────────────
if command -v python3 &>/dev/null && python3 -c "import playwright" 2>/dev/null; then
    log "Installing Playwright browser binaries (chromium)..."
    python3 -m playwright install chromium --with-deps 2>/dev/null && ok "Playwright chromium installed" || warn "Playwright browser install failed — run manually: playwright install"
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
