# ─────────────────────────────────────────────────────────────────────────────
# antigravity-skills-hub — setup.ps1
# One-command installer for Windows (PowerShell)
# Architected by Jamemm (@JameMy0001)
# https://github.com/JameMy0001/antigravity-skills-hub
#
# Run as Administrator: .\setup.ps1
# ─────────────────────────────────────────────────────────────────────────────
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ⚡ Antigravity Skills Hub — Windows Setup Installer" -ForegroundColor Cyan
Write-Host "  By Jamemm (@JameMy0001)" -ForegroundColor Cyan
Write-Host "  https://github.com/JameMy0001/antigravity-skills-hub" -ForegroundColor Cyan
Write-Host ""

# ── Detect vault root ─────────────────────────────────────────────────────────
$VaultDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Join-Path $VaultDir "Skills"

Write-Host "[setup] Vault root: $VaultDir" -ForegroundColor Gray
Write-Host "[setup] Skills dir: $SkillsDir" -ForegroundColor Gray

if (-not (Test-Path $SkillsDir)) {
    Write-Error "Skills directory not found at: $SkillsDir`nMake sure you cloned the full repository."
    exit 1
}

$SkillCount = (Get-ChildItem $SkillsDir -Directory).Count
Write-Host "[setup] Found $SkillCount skills in vault" -ForegroundColor Gray

# ── Check for Admin privileges ────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Directory junctions require elevated privileges."
    Write-Warning "Please re-run this script as Administrator for full functionality."
}

# ── Junction: Google Antigravity ──────────────────────────────────────────────
$AntigravitySkills = "$env:USERPROFILE\.gemini\config\skills"
Write-Host "[setup] Setting up Google Antigravity junction → $AntigravitySkills" -ForegroundColor Gray

$AntigravityParent = Split-Path $AntigravitySkills
if (-not (Test-Path $AntigravityParent)) { New-Item -ItemType Directory -Path $AntigravityParent -Force | Out-Null }

if (Test-Path $AntigravitySkills) {
    Write-Warning "Path already exists at $AntigravitySkills (skipping)"
} else {
    try {
        cmd /c mklink /J `"$AntigravitySkills`" `"$SkillsDir`" 2>$null
        Write-Host "[  ✅  ] Junction created → $AntigravitySkills" -ForegroundColor Green
    } catch {
        Write-Warning "Could not create junction. Trying directory symlink..."
        New-Item -ItemType SymbolicLink -Path $AntigravitySkills -Target $SkillsDir -Force | Out-Null
        Write-Host "[  ✅  ] Symlink created → $AntigravitySkills" -ForegroundColor Green
    }
}

# ── Junction: Cursor IDE ──────────────────────────────────────────────────────
$CursorSkills = "$env:USERPROFILE\.cursor\skills"
Write-Host "[setup] Setting up Cursor IDE junction → $CursorSkills" -ForegroundColor Gray

$CursorParent = Split-Path $CursorSkills
if (-not (Test-Path $CursorParent)) { New-Item -ItemType Directory -Path $CursorParent -Force | Out-Null }

if (Test-Path $CursorSkills) {
    Write-Warning "Path already exists at $CursorSkills (skipping)"
} else {
    try {
        cmd /c mklink /J `"$CursorSkills`" `"$SkillsDir`" 2>$null
        Write-Host "[  ✅  ] Junction created → $CursorSkills" -ForegroundColor Green
    } catch {
        New-Item -ItemType SymbolicLink -Path $CursorSkills -Target $SkillsDir -Force | Out-Null
        Write-Host "[  ✅  ] Symlink created → $CursorSkills" -ForegroundColor Green
    }
}

# ── Python dependencies ────────────────────────────────────────────────────────
Write-Host "[setup] Installing Python dependencies..." -ForegroundColor Gray
$RequirementsPath = Join-Path $VaultDir "requirements.txt"

try {
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "[setup] Using uv (fast Python package manager)" -ForegroundColor Gray
        uv pip install -r $RequirementsPath
    } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
        pip install -r $RequirementsPath
    } else {
        Write-Warning "No pip or uv found. Install Python 3.9+ from https://python.org then run: pip install -r requirements.txt"
    }
    Write-Host "[  ✅  ] Python dependencies installed" -ForegroundColor Green
} catch {
    Write-Warning "Dependency install failed: $($_.Exception.Message)"
}

# ── Verification ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[setup] Running vault verification..." -ForegroundColor Gray
$VerifyScript = Join-Path $VaultDir "verify_skills_vault.py"
try {
    python $VerifyScript
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✅ All $SkillCount skills installed and verified!" -ForegroundColor Green
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  🎯 Google Antigravity: ready at ~/.gemini/config/skills" -ForegroundColor Cyan
    Write-Host "  🎯 Cursor IDE:         ready at ~/.cursor/skills" -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Warning "Verification completed with warnings. See output above for details."
}
