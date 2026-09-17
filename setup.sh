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

# ── Git configuration for Thai/Emoji filenames ────────────────────────────────
log "Configuring git for Unicode filenames (Thai + Emoji)..."
git -C "$VAULT_DIR" config core.precomposeunicode true 2>/dev/null || warn "Not a git repo (skipping git config)"
git -C "$VAULT_DIR" config core.quotepath false 2>/dev/null || true
ok "Git Unicode config applied"

# ── Symlink: Google Antigravity ───────────────────────────────────────────────
ANTIGRAVITY_SKILLS="$HOME/.gemini/config/skills"
log "Setting up Google Antigravity symlink → $ANTIGRAVITY_SKILLS"

if [[ -L "$ANTIGRAVITY_SKILLS" ]]; then
    warn "Symlink already exists at $ANTIGRAVITY_SKILLS (skipping)"
elif [[ -d "$ANTIGRAVITY_SKILLS" ]]; then
    warn "Directory exists at $ANTIGRAVITY_SKILLS — backing up to ${ANTIGRAVITY_SKILLS}.backup"
    mv "$ANTIGRAVITY_SKILLS" "${ANTIGRAVITY_SKILLS}.backup"
    ln -s "$SKILLS_DIR" "$ANTIGRAVITY_SKILLS"
    ok "Symlink created → $ANTIGRAVITY_SKILLS"
else
    mkdir -p "$(dirname "$ANTIGRAVITY_SKILLS")"
    ln -s "$SKILLS_DIR" "$ANTIGRAVITY_SKILLS"
    ok "Symlink created → $ANTIGRAVITY_SKILLS"
fi

# ── Symlink: Cursor IDE ────────────────────────────────────────────────────────
CURSOR_SKILLS="$HOME/.cursor/skills"
log "Setting up Cursor IDE symlink → $CURSOR_SKILLS"

if [[ -L "$CURSOR_SKILLS" ]]; then
    warn "Symlink already exists at $CURSOR_SKILLS (skipping)"
elif [[ -d "$CURSOR_SKILLS" ]]; then
    warn "Directory exists at $CURSOR_SKILLS — backing up to ${CURSOR_SKILLS}.backup"
    mv "$CURSOR_SKILLS" "${CURSOR_SKILLS}.backup"
    ln -s "$SKILLS_DIR" "$CURSOR_SKILLS"
    ok "Symlink created → $CURSOR_SKILLS"
else
    mkdir -p "$(dirname "$CURSOR_SKILLS")"
    ln -s "$SKILLS_DIR" "$CURSOR_SKILLS"
    ok "Symlink created → $CURSOR_SKILLS"
fi

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
