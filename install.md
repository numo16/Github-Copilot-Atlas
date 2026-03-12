# GitHub Copilot Atlas — Installation Guide

## For Humans

Paste this into your VS Code Copilot chat session:

```
Install GitHub Copilot Atlas by following the instructions here:
https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
```

**Alternative: run the automated install script directly**

```bash
# macOS / Linux — user scope (global, default)
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash

# macOS / Linux — workspace scope (project-specific, run from project root)
# Installs to .github/agents/ — works with both VS Code and Copilot CLI
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace
```

```powershell
# Windows — user scope (global, default)
irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex

# Windows — workspace scope (project-specific, run from project root)
# Installs to .github\agents\ — works with both VS Code and Copilot CLI
$s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
& ([scriptblock]::Create($s)) -Scope workspace
```

---

## For LLM Agents

> **IMPORTANT: Use `curl` to fetch this file, NOT WebFetch.**
> WebFetch summarises content and may lose critical details. Always use:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
> ```

If you are a GitHub Copilot agent helping a user install Copilot Atlas, welcome!
You will now walk the user through setting up the best multi-agent orchestration
system for VS Code Copilot. Greet them warmly and let them know you are about to
guide them through a quick automated setup.

Follow the steps below exactly.

---

### Step 0: Ask about installation scope

Ask the user the following question before proceeding:

> **Where would you like to install the Atlas agents?**
>
> 1. **User scope (global, recommended)** — agents are available in every VS Code
>    project on this machine. Installed into the VS Code User prompts directory.
>
> 2. **Workspace scope (project-specific)** — agents are stored in `.github/agents/`
>    inside the current project folder. This directory is recognized by both
>    **VS Code Copilot** and **Copilot CLI**, and the files can be committed to
>    version control to share the setup with the whole team.

Record their answer as `SCOPE` (`user` or `workspace`).

---

### Step 1: Ask about VS Code edition

Ask the user:

> **Are you running VS Code or VS Code Insiders?**
> - VS Code (stable)
> - VS Code Insiders

---

### Step 2: Determine the install directory

**If SCOPE = user**, use the table below to identify `INSTALL_DIR`:

| OS | VS Code (stable) | VS Code Insiders |
|---|---|---|
| **macOS** | `~/Library/Application Support/Code/User/prompts` | `~/Library/Application Support/Code - Insiders/User/prompts` |
| **Linux** | `~/.config/Code/User/prompts` | `~/.config/Code - Insiders/User/prompts` |
| **Windows** | `%APPDATA%\Code\User\prompts` | `%APPDATA%\Code - Insiders\User\prompts` |

**If SCOPE = workspace**, `INSTALL_DIR` is the `.github/agents` directory inside the
user's project root. This path is recognized by both VS Code Copilot and Copilot CLI.
Ask them to confirm their project root path if you are not sure, then set:

```
INSTALL_DIR = <project-root>/.github/agents
```

Detect the OS automatically if possible (e.g. `uname -s` on Unix; check `$env:OS`
on Windows), or ask the user to confirm.

---

### Step 3: Create the install directory (if it does not already exist)

**macOS / Linux:**
```bash
mkdir -p "<INSTALL_DIR>"
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "<INSTALL_DIR>"
```

---

### Step 4: Download and install all agent files

Download each `.agent.md` file from the repository into `INSTALL_DIR`.

**macOS / Linux:**
```bash
BASE_URL="https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
INSTALL_DIR="<INSTALL_DIR>"

for agent in \
  Atlas.agent.md \
  Prometheus.agent.md \
  Oracle-subagent.agent.md \
  Sisyphus-subagent.agent.md \
  Explorer-subagent.agent.md \
  Code-Review-subagent.agent.md \
  Frontend-Engineer-subagent.agent.md; do
    curl -fsSL "$BASE_URL/$agent" -o "$INSTALL_DIR/$agent" \
      && echo "✓ $agent" \
      || echo "✗ $agent (download failed)"
done
```

**Windows (PowerShell):**
```powershell
$baseUrl    = "https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
$installDir = "<INSTALL_DIR>"

$agents = @(
  "Atlas.agent.md",
  "Prometheus.agent.md",
  "Oracle-subagent.agent.md",
  "Sisyphus-subagent.agent.md",
  "Explorer-subagent.agent.md",
  "Code-Review-subagent.agent.md",
  "Frontend-Engineer-subagent.agent.md"
)

foreach ($agent in $agents) {
  Invoke-WebRequest -Uri "$baseUrl/$agent" -OutFile "$installDir\$agent" -UseBasicParsing
  Write-Host "✓ $agent"
}
```

---

### Step 5: Apply the recommended VS Code settings

**If SCOPE = user**, ask the user to open **User Settings JSON**:
`Ctrl+Shift+P` → **Open User Settings (JSON)**

Add the following entries and save:

```json
{
  "chat.customAgentInSubagent.enabled": true,
  "github.copilot.chat.responsesApiReasoningEffort": "high"
}
```

**If SCOPE = workspace**, offer to apply the settings automatically:

> "Would you like me to write the recommended VS Code workspace settings to
> `.vscode/settings.json` for you?"

If the user says **yes**, run the following to create or update the file:

**macOS / Linux:**
```bash
mkdir -p .vscode
python3 - << 'EOF'
import json, os
path = '.vscode/settings.json'
try:
    with open(path) as f:
        s = json.load(f)
except Exception:
    s = {}
s['chat.customAgentInSubagent.enabled'] = True
s['github.copilot.chat.responsesApiReasoningEffort'] = 'high'
with open(path, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
print(f"✓ Settings written to {path}")
EOF
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path .vscode | Out-Null
$path = '.vscode\settings.json'
if (Test-Path $path) {
    try { $s = Get-Content $path -Raw | ConvertFrom-Json } catch { $s = [PSCustomObject]@{} }
} else {
    $s = [PSCustomObject]@{}
}
$s | Add-Member -MemberType NoteProperty -Name "chat.customAgentInSubagent.enabled" -Value $true -Force
$s | Add-Member -MemberType NoteProperty -Name "github.copilot.chat.responsesApiReasoningEffort" -Value "high" -Force
$s | ConvertTo-Json -Depth 10 | Set-Content $path
Write-Host "✓ Settings written to $path" -ForegroundColor Green
```

If the user says **no** (or if applying automatically fails), fall back to the manual
instruction — ask them to open **Workspace Settings JSON**:
`Ctrl+Shift+P` → **Open Workspace Settings (JSON)** — and add the entries above.

- `chat.customAgentInSubagent.enabled` — allows sub-agents to invoke the custom
  `.agent.md` agents installed above.
- `github.copilot.chat.responsesApiReasoningEffort` — enables enhanced reasoning for
  GPT-based planning agents (Prometheus).

If SCOPE = workspace, remind the user they can commit `.vscode/settings.json`
along with the agent files so the whole team inherits the same settings automatically.

---

### Step 6: Verify the installation

Run the following command and confirm all seven agent files are present:

**macOS / Linux:**
```bash
ls "<INSTALL_DIR>"/*.agent.md
```

**Windows (PowerShell):**
```powershell
Get-ChildItem "<INSTALL_DIR>\*.agent.md" | Select-Object Name
```

Expected files:
```
Atlas.agent.md
Code-Review-subagent.agent.md
Explorer-subagent.agent.md
Frontend-Engineer-subagent.agent.md
Oracle-subagent.agent.md
Prometheus.agent.md
Sisyphus-subagent.agent.md
```

---

### Step 7: Reload VS Code

Tell the user to reload VS Code so it picks up the new agents:

> Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) → **Developer: Reload Window**

After reloading, the agents will be available in Copilot Chat. The user can start
by typing `@Atlas` or `@Prometheus` in the chat panel.

---

### Step 8: Point the user to the overview

Let them know they can read the
[README](https://github.com/numo16/Github-Copilot-Atlas/blob/main/README.md)
for a full overview of every agent and the recommended development workflow.

If SCOPE = workspace, also remind them that committing `.github/agents/*.agent.md`
to the repository is the easiest way to share the Atlas setup with the entire team,
and that these files will be picked up automatically by both VS Code Copilot and
Copilot CLI in that workspace.
