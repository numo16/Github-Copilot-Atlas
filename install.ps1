# install.ps1 — GitHub Copilot Atlas installer for Windows (PowerShell)
#
# Usage (user/global scope — default):
#   irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex
#
# Usage (workspace/project scope — run from your project root):
#   $s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
#   & ([scriptblock]::Create($s)) -Scope workspace
#
# Parameters:
#   -Scope user        Install into the VS Code User prompts directory (default, available in all projects)
#   -Scope workspace   Install into .github\agents\ in the current directory (works with VS Code and Copilot CLI)

param(
  [ValidateSet("user", "workspace")]
  [string]$Scope = "user"
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"

$Agents = @(
  "Atlas.agent.md",
  "Prometheus.agent.md",
  "Oracle-subagent.agent.md",
  "Sisyphus-subagent.agent.md",
  "Explorer-subagent.agent.md",
  "Code-Review-subagent.agent.md",
  "Frontend-Engineer-subagent.agent.md"
)

# ── Detect VS Code edition ─────────────────────────────────────────────────────
function Get-UserPromptsDir {
  $stableDir   = Join-Path $env:APPDATA "Code\User\prompts"
  $insidersDir = Join-Path $env:APPDATA "Code - Insiders\User\prompts"

  # Prefer whichever edition directory already exists; fall back to stable.
  if (Test-Path $insidersDir) {
    return $insidersDir
  }
  return $stableDir
}

# ── Resolve install directory ──────────────────────────────────────────────────
if ($Scope -eq "workspace") {
  $InstallDir = if ($env:COPILOT_ATLAS_PROMPTS_DIR) {
    $env:COPILOT_ATLAS_PROMPTS_DIR
  } else {
    Join-Path (Get-Location) ".github\agents"
  }
  $ScopeLabel = "workspace (.github\agents\)"
} else {
  $InstallDir = if ($env:COPILOT_ATLAS_PROMPTS_DIR) {
    $env:COPILOT_ATLAS_PROMPTS_DIR
  } else {
    Get-UserPromptsDir
  }
  $ScopeLabel = "user (global)"
}

# ── Intro ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      GitHub Copilot Atlas — Installer     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "[Atlas] Scope       : $ScopeLabel" -ForegroundColor Cyan
Write-Host "[Atlas] Install dir : $InstallDir" -ForegroundColor Cyan
Write-Host ""

# ── Create install directory ───────────────────────────────────────────────────
if (-not (Test-Path $InstallDir)) {
  Write-Host "[Atlas] Creating directory ..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# ── Download agents ────────────────────────────────────────────────────────────
Write-Host "[Atlas] Downloading agent files ..." -ForegroundColor Cyan
Write-Host ""

$Failed = 0
foreach ($agent in $Agents) {
  $url  = "$BaseUrl/$agent"
  $dest = Join-Path $InstallDir $agent
  try {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Host "  ✓ $agent" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ $agent  (download failed: $_)" -ForegroundColor Red
    $Failed++
  }
}

Write-Host ""

# ── Result ─────────────────────────────────────────────────────────────────────
if ($Failed -gt 0) {
  Write-Host "✗ $Failed agent file(s) failed to download. Check your internet connection and try again." -ForegroundColor Red
  exit 1
}

Write-Host "✓ All agents installed to: $InstallDir" -ForegroundColor Green
Write-Host ""

if ($Scope -eq "workspace") {
  Write-Host "⚠ Workspace install — agents are available only in this project (via VS Code and Copilot CLI)." -ForegroundColor Yellow
  Write-Host "  Commit the .github\agents\*.agent.md files to share them with your team."
  Write-Host ""
}

# ── Apply VS Code workspace settings (workspace scope only) ───────────────────
$SettingsApplied = $false
if ($Scope -eq "workspace") {
  $VsCodeDir      = Join-Path (Get-Location) ".vscode"
  $SettingsFile   = Join-Path $VsCodeDir "settings.json"

  $applySettings = Read-Host "[Atlas] Apply recommended VS Code workspace settings to '$SettingsFile'? [Y/n]"

  if ($applySettings -notmatch '^[Nn]') {
    if (-not (Test-Path $VsCodeDir)) {
      New-Item -ItemType Directory -Force -Path $VsCodeDir | Out-Null
    }

    if (Test-Path $SettingsFile) {
      try {
        $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
      } catch {
        $settings = [PSCustomObject]@{}
      }
    } else {
      $settings = [PSCustomObject]@{}
    }

    $settings | Add-Member -MemberType NoteProperty -Name "chat.customAgentInSubagent.enabled"                   -Value $true  -Force
    $settings | Add-Member -MemberType NoteProperty -Name "github.copilot.chat.responsesApiReasoningEffort" -Value "high" -Force

    $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
    Write-Host "✓ Applied settings to $SettingsFile" -ForegroundColor Green
    $SettingsApplied = $true
  }
  Write-Host ""
}

# ── Next steps ─────────────────────────────────────────────────────────────────
Write-Host "Next steps:" -ForegroundColor Yellow
$step = 1
if (-not $SettingsApplied) {
  if ($Scope -eq "user") {
    Write-Host "  $step. Open VS Code User Settings JSON (Ctrl+Shift+P → 'Open User Settings (JSON)')"
  } else {
    Write-Host "  $step. Open VS Code Workspace Settings JSON (Ctrl+Shift+P → 'Open Workspace Settings (JSON)')"
  }
  Write-Host "     and add:"
  Write-Host '     {'
  Write-Host '       "chat.customAgentInSubagent.enabled": true,'
  Write-Host '       "github.copilot.chat.responsesApiReasoningEffort": "high"'
  Write-Host '     }'
  $step++
}
Write-Host "  $step. Reload VS Code (Ctrl+Shift+P → 'Developer: Reload Window')"
$step++
Write-Host "  $step. Start chatting with @Atlas or @Prometheus in Copilot Chat!"
Write-Host ""
Write-Host "Full documentation: https://github.com/numo16/Github-Copilot-Atlas" -ForegroundColor Cyan
Write-Host ""
