#!/usr/bin/env bash
# Bauer installer for Mac and Linux
# Sets up Claude Code with a sensible default config for non-developers.
#
# Run with:    curl -sSL https://bauerai.vercel.app/install.sh | bash
# Local test:  ROCKY_LOCAL=$(pwd) bash install.sh

set -euo pipefail

say()   { printf "  %s\n" "$*"; }
ok()    { printf "  ✅  %s\n" "$*"; }
warn()  { printf "  ⚠️   %s\n" "$*"; }
blank() { printf "\n"; }

# --- Welcome ---
blank
say "🧱  Welcome to Bauer"
blank
say "This sets up Claude Code on your computer."
say "Takes about a minute. You can stop anytime with Ctrl+C."
blank
sleep 1

# --- Check Node.js ---
if ! command -v node >/dev/null 2>&1; then
    warn "Node.js isn't installed yet."
    blank
    say "Node.js is a small piece of software that Claude Code needs to run."
    say "Download it from:  https://nodejs.org/   (pick the LTS version)"
    blank
    say "Once installed, run this Bauer command again."
    exit 1
fi

# --- Install Claude Code if missing ---
if ! command -v claude >/dev/null 2>&1; then
    say "📦  Installing Claude Code..."
    if ! npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        warn "The install didn't work. You might need admin permissions:"
        blank
        say "    sudo npm install -g @anthropic-ai/claude-code"
        blank
        exit 1
    fi
    ok "Claude Code installed"
    blank
fi

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

# --- Skills per persona (kept in sync with /personas/*/skills/) ---
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

# --- Source: local file copy or remote download ---
ROCKY_BASE="${ROCKY_BASE:-https://bauerai.vercel.app}"
LOCAL="${ROCKY_LOCAL:-}"

fetch_file() {
    local rel="$1" dest="$2"
    if [ -n "$LOCAL" ]; then
        cp "$LOCAL/$rel" "$dest"
    else
        if ! curl -sSLf "$ROCKY_BASE/$rel" -o "$dest"; then
            warn "Couldn't download $rel"
            warn "Check your internet connection and try again."
            exit 1
        fi
    fi
}

# --- Download CLAUDE.md ---
fetch_file "personas/$persona/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# --- Download each skill ---
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
say "To start using Claude, type:"
blank
say "    claude"
blank
say "And press Enter."
blank
say "First-time tip — try asking Claude something like..."
case "$persona" in
    business-owner)
        say "    \"Help me draft a follow-up email to a lead I haven't heard back from in two weeks.\"" ;;
    side-project)
        say "    \"I have 3 hours this Saturday. What's the smallest useful thing I should ship?\"" ;;
    freelancer)
        say "    \"Draft this week's status update for [client]. Notes: shipped the homepage, blocked on copy approval.\"" ;;
esac
blank
