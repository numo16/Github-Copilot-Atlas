# install.ps1 — GitHub Copilot Atlas installer for Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex

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
function Get-PromptsDir {
  $stableDir   = Join-Path $env:APPDATA "Code\User\prompts"
  $insidersDir = Join-Path $env:APPDATA "Code - Insiders\User\prompts"

  # Prefer whichever edition directory already exists; fall back to stable.
  if (Test-Path $insidersDir) {
    return $insidersDir
  }
  return $stableDir
}

# Allow override via environment variable
$PromptsDir = if ($env:COPILOT_ATLAS_PROMPTS_DIR) {
  $env:COPILOT_ATLAS_PROMPTS_DIR
} else {
  Get-PromptsDir
}

# ── Intro ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      GitHub Copilot Atlas — Installer     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "[Atlas] Prompts dir : $PromptsDir" -ForegroundColor Cyan
Write-Host ""

# ── Create prompts directory ───────────────────────────────────────────────────
if (-not (Test-Path $PromptsDir)) {
  Write-Host "[Atlas] Creating prompts directory ..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $PromptsDir | Out-Null
}

# ── Download agents ────────────────────────────────────────────────────────────
Write-Host "[Atlas] Downloading agent files ..." -ForegroundColor Cyan
Write-Host ""

$Failed = 0
foreach ($agent in $Agents) {
  $url  = "$BaseUrl/$agent"
  $dest = Join-Path $PromptsDir $agent
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

Write-Host "✓ All agents installed to: $PromptsDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open VS Code User Settings JSON (Ctrl+Shift+P → 'Open User Settings (JSON)')"
Write-Host "     and add:"
Write-Host '     {'
Write-Host '       "chat.customAgentInSubagent.enabled": true,'
Write-Host '       "github.copilot.chat.responsesApiReasoningEffort": "high"'
Write-Host '     }'
Write-Host "  2. Reload VS Code (Ctrl+Shift+P → 'Developer: Reload Window')"
Write-Host "  3. Start chatting with @Atlas or @Prometheus in Copilot Chat!"
Write-Host ""
Write-Host "Full documentation: https://github.com/numo16/Github-Copilot-Atlas" -ForegroundColor Cyan
Write-Host ""
