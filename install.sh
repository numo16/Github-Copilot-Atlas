#!/usr/bin/env bash
# install.sh — GitHub Copilot Atlas installer for macOS and Linux
#
# Usage (user/global scope — default):
#   curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash
#
# Usage (workspace/project scope — run from your project root):
#   curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace
#
# Flags:
#   --scope=user        Install into the VS Code User prompts directory (default, available in all projects)
#   --scope=workspace   Install into .github/agents/ in the current directory (works with VS Code and Copilot CLI)

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"

AGENTS=(
  "Atlas.agent.md"
  "Prometheus.agent.md"
  "Oracle-subagent.agent.md"
  "Sisyphus-subagent.agent.md"
  "Explorer-subagent.agent.md"
  "Code-Review-subagent.agent.md"
  "Frontend-Engineer-subagent.agent.md"
)

# ── Color helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}${BOLD}[Atlas]${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*" >&2; }

# ── Parse flags ───────────────────────────────────────────────────────────────
SCOPE="user"
for arg in "$@"; do
  case "$arg" in
    --scope=user)      SCOPE="user" ;;
    --scope=workspace) SCOPE="workspace" ;;
    *)
      error "Unknown argument: $arg"
      echo "Usage: $0 [--scope=user|workspace]" >&2
      exit 1
      ;;
  esac
done

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) OS_NAME="macOS" ;;
  Linux)  OS_NAME="Linux" ;;
  *)
    error "Unsupported OS: $OS. Please install manually — see install.md."
    exit 1
    ;;
esac

# ── Resolve install directory ─────────────────────────────────────────────────
detect_user_prompts_dir() {
  local stable_dir insiders_dir

  if [[ "$OS_NAME" == "macOS" ]]; then
    stable_dir="$HOME/Library/Application Support/Code/User/prompts"
    insiders_dir="$HOME/Library/Application Support/Code - Insiders/User/prompts"
  else
    stable_dir="$HOME/.config/Code/User/prompts"
    insiders_dir="$HOME/.config/Code - Insiders/User/prompts"
  fi

  # Prefer whichever edition is already installed; fall back to stable.
  if [[ -d "$insiders_dir" ]]; then
    echo "$insiders_dir"
  else
    echo "$stable_dir"
  fi
}

if [[ "$SCOPE" == "workspace" ]]; then
  INSTALL_DIR="${COPILOT_ATLAS_PROMPTS_DIR:-$(pwd)/.github/agents}"
  SCOPE_LABEL="workspace (.github/agents/)"
else
  INSTALL_DIR="${COPILOT_ATLAS_PROMPTS_DIR:-$(detect_user_prompts_dir)}"
  SCOPE_LABEL="user (global)"
fi

# ── Intro ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║      GitHub Copilot Atlas — Installer     ║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════════════════╝${RESET}"
echo ""
info "Detected OS  : $OS_NAME"
info "Scope        : $SCOPE_LABEL"
info "Install dir  : $INSTALL_DIR"
echo ""

# ── Create install directory ──────────────────────────────────────────────────
if [[ ! -d "$INSTALL_DIR" ]]; then
  info "Creating directory …"
  mkdir -p "$INSTALL_DIR"
fi

# ── Download agents ───────────────────────────────────────────────────────────
info "Downloading agent files …"
echo ""

FAILED=0
for agent in "${AGENTS[@]}"; do
  if curl -fsSL "$BASE_URL/$agent" -o "$INSTALL_DIR/$agent"; then
    success "$agent"
  else
    error "$agent  (download failed)"
    FAILED=1
  fi
done

echo ""

# ── Result ────────────────────────────────────────────────────────────────────
if [[ "$FAILED" -ne 0 ]]; then
  error "One or more agent files failed to download. Check your internet connection and try again."
  exit 1
fi

success "All agents installed to: $INSTALL_DIR"
echo ""

if [[ "$SCOPE" == "workspace" ]]; then
  warn "Workspace install — agents are available only in this project (via VS Code and Copilot CLI)."
  echo "  Commit the .github/agents/*.agent.md files to share them with your team."
  echo ""
fi

# ── Apply VS Code workspace settings (workspace scope only) ───────────────────
SETTINGS_APPLIED=0
if [[ "$SCOPE" == "workspace" ]]; then
  VSCODE_SETTINGS_DIR="$(pwd)/.vscode"
  VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

  printf "${CYAN}${BOLD}[Atlas]${RESET} Apply recommended VS Code workspace settings\n"
  printf "       to ${BOLD}%s${RESET}? [Y/n] " "$VSCODE_SETTINGS_FILE"
  read -r _apply_settings </dev/tty 2>/dev/null || _apply_settings="y"

  if [[ "${_apply_settings,,}" != "n" ]]; then
    mkdir -p "$VSCODE_SETTINGS_DIR"
    _py_tmp=$(mktemp /tmp/atlas_settings_XXXXXX.py)
    cat > "$_py_tmp" << 'PYEOF'
import json, sys
path = sys.argv[1]
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
PYEOF
    if python3 "$_py_tmp" "$VSCODE_SETTINGS_FILE" 2>/dev/null; then
      success "Applied settings to $VSCODE_SETTINGS_FILE"
      SETTINGS_APPLIED=1
    else
      warn "Could not apply settings automatically (python3 not found)."
    fi
    rm -f "$_py_tmp"
  fi
  echo ""
fi

# ── Next steps ────────────────────────────────────────────────────────────────
warn "Next steps:"
STEP=1
if [[ "$SETTINGS_APPLIED" -eq 0 ]]; then
  if [[ "$SCOPE" == "user" ]]; then
    echo "  $STEP. Open VS Code User Settings JSON (Ctrl+Shift+P → 'Open User Settings (JSON)')"
    echo "     and add:"
  else
    echo "  $STEP. Open VS Code Workspace Settings JSON (Ctrl+Shift+P → 'Open Workspace Settings (JSON)')"
    echo "     and add:"
  fi
  echo '     {'
  echo '       "chat.customAgentInSubagent.enabled": true,'
  echo '       "github.copilot.chat.responsesApiReasoningEffort": "high"'
  echo '     }'
  STEP=$((STEP + 1))
fi
echo "  $STEP. Reload VS Code (Ctrl+Shift+P → 'Developer: Reload Window')"
STEP=$((STEP + 1))
echo "  $STEP. Start chatting with @Atlas or @Prometheus in Copilot Chat!"
echo ""
echo -e "${BOLD}Full documentation:${RESET} https://github.com/numo16/Github-Copilot-Atlas"
echo ""
