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

function Get-BackupPath {
    param([string]$Path)
    $backupPath = "$Path.backup"
    if (Test-Path -LiteralPath $backupPath) {
        $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $backupPath = "$backupPath.$timestamp"
    }
    return $backupPath
}

function Ensure-SkillsLink {
    param(
        [string]$LinkPath,
        [string]$Label
    )

    $parent = Split-Path $LinkPath
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    $desiredResolved = (Resolve-Path -LiteralPath $SkillsDir).Path
    $needsRecreate = $false

    if (Test-Path -LiteralPath $LinkPath) {
        $item = Get-Item -LiteralPath $LinkPath -Force
        $existingResolved = (Resolve-Path -LiteralPath $LinkPath).Path
        $isReparsePoint = (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)

        if ($isReparsePoint -and $existingResolved -eq $desiredResolved) {
            Write-Host "[  ✅  ] $Label link already correct → $LinkPath" -ForegroundColor Green
            return
        }

        $needsRecreate = $true
    }

    if ($needsRecreate) {
        $backupPath = Get-BackupPath -Path $LinkPath
        Move-Item -LiteralPath $LinkPath -Destination $backupPath
        Write-Warning "$Label existing path backed up to $backupPath"
    }

    try {
        cmd /c mklink /J `"$LinkPath`" `"$SkillsDir`" 2>$null
        Write-Host "[  ✅  ] Junction created → $LinkPath" -ForegroundColor Green
    } catch {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $SkillsDir -Force | Out-Null
        Write-Host "[  ✅  ] Symlink created → $LinkPath" -ForegroundColor Green
    }
}

function Invoke-AvailablePython {
    param([string[]]$Arguments)

    if (Get-Command python -ErrorAction SilentlyContinue) {
        & python @Arguments
        return $LASTEXITCODE
    }

    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py @Arguments
        return $LASTEXITCODE
    }

    throw "No Python launcher found (python/py)."
}

# ── Check for Admin privileges ────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Directory junctions require elevated privileges."
    Write-Warning "Please re-run this script as Administrator for full functionality."
}

# ── Junction: Google Antigravity ──────────────────────────────────────────────
$AntigravitySkills = "$env:USERPROFILE\.gemini\config\skills"
Write-Host "[setup] Setting up Google Antigravity junction → $AntigravitySkills" -ForegroundColor Gray
Ensure-SkillsLink -LinkPath $AntigravitySkills -Label "Google Antigravity"

# ── Junction: Cursor IDE ──────────────────────────────────────────────────────
$CursorSkills = "$env:USERPROFILE\.cursor\skills"
Write-Host "[setup] Setting up Cursor IDE junction → $CursorSkills" -ForegroundColor Gray
Ensure-SkillsLink -LinkPath $CursorSkills -Label "Cursor IDE"

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
    Invoke-AvailablePython -Arguments @($VerifyScript)
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
