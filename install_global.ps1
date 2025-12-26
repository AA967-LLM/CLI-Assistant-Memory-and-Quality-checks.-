<#
.SYNOPSIS
    UNIVERSAL AI ENVIRONMENT INSTALLER (Windows Final + Auto-Hygiene)
.DESCRIPTION
    Installs Global Quality Gates, Hardware Profiles, and Auto-Cleaning Tools.
#>

# -----------------------------------------------------------------------------
# DISCLAIMER:
# This script is provided "as is" without warranty of any kind, express or
# implied, including but not limited to the warranties of merchantability,
# fitness for a particular purpose and noninfringement. In no event shall the
# authors or copyright holders be liable for any claim, damages or other
# liability, whether in an action of contract, tort or otherwise, arising from,
# out of or in connection with the software or the use or other dealings in the
# software.
#
# USE AT YOUR OWN RISK.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

# 1. Target Global Directories
$GlobalConfigDir = "$env:USERPROFILE\.gemini"
$GlobalBinDir    = "$GlobalConfigDir\bin"
$ArchiveDir      = "$GlobalConfigDir\archive"
$ScheduleFile    = "$GlobalConfigDir\ai-clean-last-run.txt"

Write-Host "Starting Global AI Setup..." -ForegroundColor Cyan

# Create directories (idempotent)
New-Item -ItemType Directory -Force -Path $GlobalConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path $GlobalBinDir | Out-Null
New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

# -----------------------------
# 2. WRITE GLOBAL "BRAIN"
# -----------------------------
Write-Host "Installing Global System Instructions..." -ForegroundColor Yellow

$GlobalInstructions = @"
# GLOBAL SYSTEM INSTRUCTIONS
**Authority:** Master Configuration
**Hardware:** i7 (Limited CPU) | 32GB RAM
**Enforcement:** Strict Quality Gates

## 1. EXECUTION INVARIANT
1. **READ:** Check .ai/WORKLOG.md. Require initialization if missing.
2. **INIT:** If intent="New Project" or WORKLOG missing → Run ai-init AUTO.
3. **PLAN:** Outline changes.
4. **BUILD:** Write clean code.
5. **VERIFY:** Suggest tests/checks.
6. **RECORD:** Update the log.

## 2. HARDWARE PROTOCOL
- CPU: Do NOT scan entire drives.
- RAM: Load files explicitly.
- Anti-Hallucination: Always read files.

## 3. ARTIFACT & HYGIENE
- Artifacts: Intermediate logs are temporary.
- Cleanup: Auto-archives >30 days.
"@

Set-Content -Path "$GlobalConfigDir\GEMINI.md" -Value $GlobalInstructions -Encoding utf8
Copy-Item "$GlobalConfigDir\GEMINI.md" -Destination "$GlobalConfigDir\CLAUDE.md" -Force

# -----------------------------
# 3. WRITE GLOBAL IGNORE FILE
# -----------------------------
Write-Host "Installing Global Ignore Rules..." -ForegroundColor Yellow

$GlobalIgnore = @"
**/node_modules/
**/.git/
**/dist/
**/build/
**/coverage/
**/.next/
**/*.min.js
.DS_Store
"@
Set-Content -Path "$env:USERPROFILE\.geminiignore" -Value $GlobalIgnore
Set-Content -Path "$env:USERPROFILE\.claudeignore" -Value $GlobalIgnore

# -----------------------------
# 4. INSTALL TOOLS
# -----------------------------
Write-Host "Installing Tools..." -ForegroundColor Yellow

# Verify Script
$VerifyScript = @"
# DISCLAIMER: Use at your own risk. Part of Universal AI Environment.
Write-Host 'GLOBAL QUALITY GATE CHECK' -ForegroundColor Cyan
if (Test-Path '.ai\WORKLOG.md') {
    Write-Host 'Project Log Found.' -ForegroundColor Green
} else {
    Write-Host 'No WORKLOG found.' -ForegroundColor Yellow
    Write-Host 'Run ai-init to initialize.' -ForegroundColor Gray
}
"@
Set-Content -Path "$GlobalBinDir\verify.ps1" -Value $VerifyScript

# Hygiene + Archive Script
$CleanScript = @"
# DISCLAIMER: Use at your own risk. This script deletes/archives files.
param([int]`$Days = 30)
`$Found = `$false
`$ArchiveDir = '$ArchiveDir'
New-Item -ItemType Directory -Force -Path `$ArchiveDir | Out-Null

Get-ChildItem -Path . -Recurse -Directory -Filter '.ai' | ForEach-Object {
    if (`$_.LastWriteTime -lt (Get-Date).AddDays(-`$Days)) {
        if (-not `$Found) { Write-Host 'RUNNING HYGIENE ARCHIVE...' -ForegroundColor Cyan; `$Found = `$true }
        
        Write-Host 'Dormant AI Context found:' `$_.FullName -ForegroundColor Yellow
        `$ProjectName = [IO.Path]::GetFileName(`$_.Parent.FullName)
        `$TimeStamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
        `$ArchiveName = Join-Path `$ArchiveDir "`$(`$TimeStamp)_`$(`$ProjectName).zip"
        
        Write-Host "Archiving to: `$ArchiveName"
        Compress-Archive -Path `$_.FullName -DestinationPath `$ArchiveName -Force
        Remove-Item -Recurse -Force -Path `$_.FullName
        Write-Host 'Archived and Removed.' -ForegroundColor Green
    }
}

Get-ChildItem -Path `$ArchiveDir -Filter '*.zip' | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-`$Days) } | ForEach-Object {
    Write-Host 'Removing old archive:' `$_.FullName -ForegroundColor Red
    Remove-Item -Force -Path `$_.FullName
}

Set-Content -Path '$ScheduleFile' -Value (Get-Date).ToString('yyyyMMdd_HHmmss')
"@
Set-Content -Path "$GlobalBinDir\clean.ps1" -Value $CleanScript

# -----------------------------------------------------------------------------
# WARNING: The following operation modifies your PowerShell profile.
# USE AT YOUR OWN RISK. SEE DISCLAIMER AT THE TOP OF THIS FILE.
# -----------------------------------------------------------------------------
# -----------------------------
# 5. SAFE POWERSHELL PROFILE UPDATE
# -----------------------------
Write-Host "Updating PowerShell Profile..." -ForegroundColor Yellow
$ProfilePath = $PROFILE
if (-not (Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }

$Marker = "# --- UNIVERSAL AI ENVIRONMENT ---"
if (-not (Select-String -Path $ProfilePath -Pattern $Marker -SimpleMatch -Quiet)) {
    $AliasCode = @"
$Marker
function ai-init {
    if (-not (Test-Path '.ai')) { New-Item -ItemType Directory -Force -Path '.ai' | Out-Null }
    if (-not (Test-Path '.ai\WORKLOG.md')) {
        "# WORKLOG`nStarted: $(Get-Date)" | Set-Content '.ai\WORKLOG.md'
        Write-Host 'AI Project Initialized.'
    } else { Write-Host 'WORKLOG exists. Skipped.' }
}
function ai-verify { & '$GlobalBinDir\verify.ps1' }
function ai-clean { & '$GlobalBinDir\clean.ps1' }

# Auto-schedule hygiene check
function ai-auto-clean {
    `$LastRunFile = '$ScheduleFile'
    `$DaysCheck = 10
    
    if (-not (Test-Path `$LastRunFile)) {
        Set-Content -Path `$LastRunFile -Value (Get-Date).ToString('yyyyMMdd_HHmmss')
        return
    }
    
    try {
        `$LastString = Get-Content `$LastRunFile -ErrorAction SilentlyContinue
        `$LastRun = [DateTime]::ParseExact(`$LastString, 'yyyyMMdd_HHmmss', `$null)
        
        if ((Get-Date) -gt `$LastRun.AddDays(`$DaysCheck)) {
            Write-Host 'Auto-Hygiene Triggered...' -ForegroundColor Cyan
            ai-clean
        }
    } catch {
        Set-Content -Path `$LastRunFile -Value (Get-Date).ToString('yyyyMMdd_HHmmss')
    }
}
ai-auto-clean
"@
    Add-Content -Path $ProfilePath -Value $AliasCode
    Write-Host "Profile updated." -ForegroundColor Green
} else { Write-Host "Profile already configured. Skipped." -ForegroundColor Gray }

Write-Host ""
Write-Host "---------------------------------------------------"
Write-Host "DISCLAIMER: Use at your own risk. See script header."
Write-Host "---------------------------------------------------"
Write-Host "GLOBAL INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "---------------------------------------------------"
Write-Host "1. Restart your terminal."
Write-Host "2. 'ai-init'       -> Start a new project"
Write-Host "3. 'ai-verify'     -> Run global quality gates"
Write-Host "4. 'ai-clean'      -> Force archive dormant files"
Write-Host "---------------------------------------------------"
