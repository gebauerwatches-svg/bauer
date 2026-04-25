#!/usr/bin/env bash
# Bauer LOCAL installer for Mac and Linux
# Sets up Bauer with an OPEN-SOURCE local AI (via Ollama) instead of Claude.
#
# Run with:    curl -sSL https://bauerai.vercel.app/install-local.sh | bash
# Local test:  ROCKY_LOCAL=$(pwd) bash install-local.sh

set -euo pipefail

say()   { printf "  %s\n" "$*"; }
ok()    { printf "  ✅  %s\n" "$*"; }
warn()  { printf "  ⚠️   %s\n" "$*"; }
blank() { printf "\n"; }

# --- Welcome ---
blank
say "🧱  Welcome to Bauer (open-source local edition)"
blank
say "This sets up Bauer with a local open-source AI instead of Claude."
say "Free to run, more privacy, no monthly subscription. Takes about 5 minutes."
blank
say "What will get installed:"
say "  • Ollama (runs the local AI on your computer)"
say "  • A small open-source model (qwen2.5-coder:7b — ~4 GB)"
say "  • Claude Code (the terminal interface — yes, even for local models)"
say "  • A bridge that connects Claude Code to Ollama"
say "  • Your Bauer persona config + skills"
blank
read -r -p "  Ready? (y/n): " ready
[[ "$ready" =~ ^[Yy] ]] || { say "Bye!"; exit 0; }
blank

# --- Check Ollama ---
if ! command -v ollama >/dev/null 2>&1; then
    say "📦  Installing Ollama..."
    if command -v brew >/dev/null 2>&1; then
        brew install ollama || {
            warn "brew install failed. Manual fix:"
            say "    Download Ollama from: https://ollama.com/download"
            exit 1
        }
    else
        warn "Homebrew not found. Manual install required:"
        blank
        say "    1. Visit:  https://ollama.com/download"
        say "    2. Download and run the macOS installer"
        say "    3. Re-run this Bauer script when done"
        exit 1
    fi
    ok "Ollama installed"
    blank
fi

# --- Start Ollama service ---
if ! pgrep -x "ollama" >/dev/null 2>&1; then
    say "▶️   Starting Ollama in the background..."
    nohup ollama serve >/tmp/ollama.log 2>&1 &
    sleep 3
fi

# --- Pull a model ---
MODEL="${BAUER_MODEL:-qwen2.5-coder:7b}"
if ! ollama list 2>/dev/null | grep -q "${MODEL%:*}"; then
    say "⬇️   Downloading model ($MODEL, ~4 GB) — this takes a few minutes the first time..."
    ollama pull "$MODEL" || {
        warn "Model download failed. Check your internet and try again."
        exit 1
    }
    ok "Model ready"
    blank
fi

# --- Install Claude Code (still the terminal interface) ---
if ! command -v node >/dev/null 2>&1; then
    warn "Node.js isn't installed yet."
    blank
    say "Node.js is needed to run Claude Code (the terminal interface)."
    say "Download from:  https://nodejs.org/   (pick LTS)"
    blank
    say "Once installed, re-run this script."
    exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
    say "📦  Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 || {
        warn "Install failed. Try: sudo npm install -g @anthropic-ai/claude-code"
        exit 1
    }
    ok "Claude Code installed"
    blank
fi

# --- Install the Ollama ↔ Claude Code bridge ---
if ! command -v ccr >/dev/null 2>&1; then
    say "🔗  Installing the Ollama bridge (claude-code-router)..."
    npm install -g @musistudio/claude-code-router >/dev/null 2>&1 || {
        warn "Bridge install failed. You can install manually with:"
        say "    npm install -g @musistudio/claude-code-router"
        say "Continuing — we'll set up config; you can install the bridge later."
    }
    blank
fi

# --- Write the bridge config ---
CCR_CONFIG_DIR="$HOME/.claude-code-router"
mkdir -p "$CCR_CONFIG_DIR"
cat > "$CCR_CONFIG_DIR/config.json" <<EOF
{
  "Providers": [
    {
      "name": "ollama",
      "api_base_url": "http://localhost:11434/v1/chat/completions",
      "api_key": "not-needed",
      "models": ["$MODEL"]
    }
  ],
  "Router": {
    "default": "ollama,$MODEL"
  }
}
EOF
ok "Bridge configured for Ollama + $MODEL"
blank

# --- Pick persona ---
say "✨  Which best describes you?"
blank
say "    1) Small business owner   -  customer comms, proposals, marketing copy"
say "    2) Side project runner    -  content, launches, scope discipline"
say "    3) Freelancer/consultant  -  client updates, scoping, scope-creep responses"
blank

persona=""
while [ -z "$persona" ]; do
    read -r -p "  Pick a number (1, 2, or 3): " choice
    case "$choice" in
        1) persona="business-owner"; persona_label="Small business owner" ;;
        2) persona="side-project";   persona_label="Side project runner" ;;
        3) persona="freelancer";     persona_label="Freelancer/consultant" ;;
        *) say "Please type 1, 2, or 3." ;;
    esac
done

blank
say "⚡  Setting up the '$persona_label' personality..."

case "$persona" in
    business-owner) skills=(customer-message proposal-or-quote marketing-copy build-agent) ;;
    side-project)   skills=(draft-content launch-copy scope-and-prioritize build-agent) ;;
    freelancer)     skills=(client-update scope-and-estimate scope-creep-response build-agent) ;;
esac

# --- Destination ---
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"

# Backup existing CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup="$CLAUDE_DIR/CLAUDE.md.before-bauer.$(date +%s)"
    mv "$CLAUDE_DIR/CLAUDE.md" "$backup"
    say "(Backed up your existing CLAUDE.md to: $backup)"
fi

# --- Source ---
ROCKY_BASE="${ROCKY_BASE:-https://bauerai.vercel.app}"
LOCAL="${ROCKY_LOCAL:-}"

fetch_file() {
    local rel="$1" dest="$2"
    if [ -n "$LOCAL" ]; then
        cp "$LOCAL/$rel" "$dest"
    else
        if ! curl -sSLf "$ROCKY_BASE/$rel" -o "$dest"; then
            warn "Couldn't download $rel"
            exit 1
        fi
    fi
}

fetch_file "personas/$persona/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

for skill in "${skills[@]}"; do
    skill_dir="$CLAUDE_DIR/skills/$skill"
    if [ -d "$skill_dir" ]; then
        backup="$skill_dir.before-bauer.$(date +%s)"
        mv "$skill_dir" "$backup"
    fi
    mkdir -p "$skill_dir"
    fetch_file "personas/$persona/skills/$skill/SKILL.md" "$skill_dir/SKILL.md"
done

# --- Done ---
blank
ok "All set!"
blank
say "To start using Bauer with your local AI, run two commands:"
blank
say "    Terminal tab 1:  ccr           (starts the bridge)"
say "    Terminal tab 2:  ccr code      (opens Claude Code via the bridge)"
blank
say "Or in one tab, run:"
blank
say "    ccr code"
blank
say "(it auto-starts the bridge when needed)"
blank
say "First-time tip — try asking..."
case "$persona" in
    business-owner)
        say "    \"Help me draft a follow-up email to a client.\"" ;;
    side-project)
        say "    \"What's the smallest useful thing I should ship this weekend?\"" ;;
    freelancer)
        say "    \"Draft this week's status update for [client]. Notes: ...\"" ;;
esac
blank
say "📝  Note: open-source local models are slower and less capable than Claude."
say "    For complex tasks, consider switching to the Claude path:"
say "    https://bauerai.vercel.app/install.sh"
blank
