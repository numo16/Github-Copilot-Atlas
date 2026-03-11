# GitHub Copilot Atlas — Installation Guide

## For Humans

Paste this into your VS Code Copilot chat session:

```
Install GitHub Copilot Atlas by following the instructions here:
https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
```

**Alternative: run the automated install script directly**

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex
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

### Step 0: Ask about VS Code edition

Ask the user one question:

> **Are you running VS Code or VS Code Insiders?**
> - VS Code (stable) → use the standard paths below
> - VS Code Insiders → use the Insiders paths below

---

### Step 1: Determine the prompts directory

Use the table below to identify `PROMPTS_DIR` for the user's OS and edition.

| OS | VS Code (stable) | VS Code Insiders |
|---|---|---|
| **macOS** | `~/Library/Application Support/Code/User/prompts` | `~/Library/Application Support/Code - Insiders/User/prompts` |
| **Linux** | `~/.config/Code/User/prompts` | `~/.config/Code - Insiders/User/prompts` |
| **Windows** | `%APPDATA%\Code\User\prompts` | `%APPDATA%\Code - Insiders\User\prompts` |

Detect the OS automatically if possible (e.g. `uname -s` on Unix; check `$env:OS` on
Windows), or ask the user to confirm.

---

### Step 2: Create the prompts directory (if it does not already exist)

**macOS / Linux:**
```bash
mkdir -p "<PROMPTS_DIR>"
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:APPDATA\Code\User\prompts"
# (replace path with Insiders path if needed)
```

---

### Step 3: Download and install all agent files

Download each `.agent.md` file from the repository into `PROMPTS_DIR`.

**macOS / Linux:**
```bash
BASE_URL="https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
PROMPTS_DIR="<PROMPTS_DIR>"

for agent in \
  Atlas.agent.md \
  Prometheus.agent.md \
  Oracle-subagent.agent.md \
  Sisyphus-subagent.agent.md \
  Explorer-subagent.agent.md \
  Code-Review-subagent.agent.md \
  Frontend-Engineer-subagent.agent.md; do
    curl -fsSL "$BASE_URL/$agent" -o "$PROMPTS_DIR/$agent" \
      && echo "✓ $agent" \
      || echo "✗ $agent (download failed)"
done
```

**Windows (PowerShell):**
```powershell
$baseUrl   = "https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
$promptsDir = "$env:APPDATA\Code\User\prompts"   # adjust for Insiders if needed

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
  Invoke-WebRequest -Uri "$baseUrl/$agent" -OutFile "$promptsDir\$agent"
  Write-Host "✓ $agent"
}
```

---

### Step 4: Apply the recommended VS Code settings

Ask the user to open their VS Code User Settings JSON
(`Ctrl+Shift+P` → **Open User Settings (JSON)**) and add the following entries:

```json
{
  "chat.customAgentInSubagent.enabled": true,
  "github.copilot.chat.responsesApiReasoningEffort": "high"
}
```

- `chat.customAgentInSubagent.enabled` — allows sub-agents to invoke the custom
  `.agent.md` agents installed above.
- `github.copilot.chat.responsesApiReasoningEffort` — enables enhanced reasoning for
  GPT-based planning agents (Prometheus).

---

### Step 5: Verify the installation

Run the following command and confirm all seven agent files are present:

**macOS / Linux:**
```bash
ls "<PROMPTS_DIR>"/*.agent.md
```

**Windows (PowerShell):**
```powershell
Get-ChildItem "$promptsDir\*.agent.md" | Select-Object Name
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

### Step 6: Reload VS Code

Tell the user to reload VS Code so it picks up the new agents:

> Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) → **Developer: Reload Window**

After reloading, the agents will be available in Copilot Chat. The user can start
by typing `@Atlas` or `@Prometheus` in the chat panel.

---

### Step 7: Point the user to the overview

Let them know they can read the
[README](https://github.com/numo16/Github-Copilot-Atlas/blob/main/README.md)
for a full overview of every agent and the recommended development workflow.
