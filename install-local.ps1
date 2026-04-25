# Bauer LOCAL installer for Windows
# Sets up Bauer with an OPEN-SOURCE local AI (via Ollama) instead of Claude.
#
# Run with:    iwr https://bauerai.vercel.app/install-local.ps1 | iex

$ErrorActionPreference = "Stop"

function Write-Say  { param([string]$msg) Write-Host "  $msg" }
function Write-Ok   { param([string]$msg) Write-Host "  ✅  $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  ⚠️   $msg" -ForegroundColor Yellow }

# --- Welcome ---
Write-Host ""
Write-Say "🧱  Welcome to Bauer (open-source local edition)"
Write-Host ""
Write-Say "This sets up Bauer with a local open-source AI instead of Claude."
Write-Say "Free to run, more privacy, no monthly subscription. Takes about 5 minutes."
Write-Host ""
Write-Say "What will get installed:"
Write-Say "  • Ollama (runs the local AI on your computer)"
Write-Say "  • A small open-source model (qwen2.5-coder:7b — ~4 GB)"
Write-Say "  • Claude Code (the terminal interface — yes, even for local models)"
Write-Say "  • A bridge that connects Claude Code to Ollama"
Write-Say "  • Your Bauer persona config + skills"
Write-Host ""
$ready = Read-Host "  Ready? (y/n)"
if ($ready -notmatch "^[Yy]") { Write-Say "Bye!"; exit 0 }
Write-Host ""

# --- Check Ollama ---
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Warn "Ollama isn't installed yet."
    Write-Host ""
    Write-Say "Manual install needed on Windows:"
    Write-Say "    1. Visit:  https://ollama.com/download"
    Write-Say "    2. Download and run OllamaSetup.exe"
    Write-Say "    3. Re-run this Bauer script when done"
    exit 1
}

# --- Start Ollama service (Windows: usually starts automatically) ---
if (-not (Get-Process -Name "ollama" -ErrorAction SilentlyContinue)) {
    Write-Say "▶️   Starting Ollama..."
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# --- Pull model ---
$model = if ($env:BAUER_MODEL) { $env:BAUER_MODEL } else { "qwen2.5-coder:7b" }
$modelBase = $model.Split(":")[0]
$installed = & ollama list 2>$null | Out-String
if ($installed -notmatch $modelBase) {
    Write-Say "⬇️   Downloading model ($model, ~4 GB) — this takes a few minutes the first time..."
    try {
        & ollama pull $model
    } catch {
        Write-Warn "Model download failed. Check your internet and try again."
        exit 1
    }
    Write-Ok "Model ready"
    Write-Host ""
}

# --- Check Node.js ---
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Warn "Node.js isn't installed yet."
    Write-Host ""
    Write-Say "Node.js is needed to run Claude Code (the terminal interface)."
    Write-Say "Download from:  https://nodejs.org/   (pick LTS)"
    Write-Host ""
    Write-Say "Once installed, re-run this script."
    exit 1
}

# --- Install Claude Code ---
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Say "📦  Installing Claude Code..."
    try {
        & npm install -g "@anthropic-ai/claude-code" 2>&1 | Out-Null
    } catch {
        Write-Warn "Install failed. Try running PowerShell as Administrator, or use:"
        Write-Say "    npm config set prefix `"$env:USERPROFILE\.npm-global`""
        Write-Say "    npm install -g @anthropic-ai/claude-code"
        exit 1
    }
    Write-Ok "Claude Code installed"
    Write-Host ""
}

# --- Install bridge ---
if (-not (Get-Command ccr -ErrorAction SilentlyContinue)) {
    Write-Say "🔗  Installing the Ollama bridge (claude-code-router)..."
    try {
        & npm install -g "claude-code-router" 2>&1 | Out-Null
    } catch {
        Write-Warn "Bridge install failed. Manual install:"
        Write-Say "    npm install -g claude-code-router"
    }
    Write-Host ""
}

# --- Write bridge config ---
# IMPORTANT: claude-code-router looks for config-router.json (not config.json)
$ccrDir = Join-Path $env:USERPROFILE ".claude-code-router"
New-Item -ItemType Directory -Force -Path $ccrDir | Out-Null
$config = @"
{
  "server": {
    "port": 3456,
    "host": "127.0.0.1"
  },
  "routing": {
    "rules": {
      "default":     { "provider": "ollama", "model": "$model" },
      "background":  { "provider": "ollama", "model": "$model" },
      "thinking":    { "provider": "ollama", "model": "$model" },
      "longcontext": { "provider": "ollama", "model": "$model" }
    },
    "defaultProvider": "ollama",
    "providers": {
      "ollama": {
        "type": "openai",
        "endpoint": "http://localhost:11434/v1/chat/completions",
        "authentication": {
          "type": "bearer",
          "credentials": { "apiKey": "not-needed" }
        },
        "settings": {
          "categoryMappings": {
            "default": true,
            "background": true,
            "thinking": true,
            "longcontext": true
          },
          "models": ["$model"],
          "defaultModel": "$model"
        }
      }
    }
  }
}
"@
Set-Content -Path (Join-Path $ccrDir "config-router.json") -Value $config
Write-Ok "Bridge configured for Ollama + $model"
Write-Host ""

# --- Pick persona ---
Write-Say "✨  Which best describes you?"
Write-Host ""
Write-Say "    1) Small business owner   -  customer comms, proposals, marketing copy"
Write-Say "    2) Side project runner    -  content, launches, scope discipline"
Write-Say "    3) Freelancer/consultant  -  client updates, scoping, scope-creep responses"
Write-Host ""

$persona = $null
$personaLabel = $null
while (-not $persona) {
    $choice = Read-Host "  Pick a number (1, 2, or 3)"
    switch ($choice) {
        "1" { $persona = "business-owner"; $personaLabel = "Small business owner" }
        "2" { $persona = "side-project";   $personaLabel = "Side project runner" }
        "3" { $persona = "freelancer";     $personaLabel = "Freelancer/consultant" }
        default { Write-Say "Please type 1, 2, or 3." }
    }
}

Write-Host ""
Write-Say "⚡  Setting up the '$personaLabel' personality..."

$skills = switch ($persona) {
    "business-owner" { @("customer-message", "proposal-or-quote", "marketing-copy", "build-agent") }
    "side-project"   { @("draft-content", "launch-copy", "scope-and-prioritize", "build-agent") }
    "freelancer"     { @("client-update", "scope-and-estimate", "scope-creep-response", "build-agent") }
}

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) {
    $stamp = [int][double]::Parse((Get-Date -UFormat %s))
    Move-Item $claudeMd "$claudeMd.before-bauer.$stamp"
}

$rockyBase = if ($env:ROCKY_BASE) { $env:ROCKY_BASE } else { "https://bauerai.vercel.app" }
$rockyLocal = $env:ROCKY_LOCAL

function Get-BauerFile {
    param([string]$rel, [string]$dest)
    if ($rockyLocal) {
        Copy-Item -Path (Join-Path $rockyLocal $rel) -Destination $dest -Force
    } else {
        try {
            Invoke-WebRequest -Uri "$rockyBase/$rel" -OutFile $dest -UseBasicParsing
        } catch {
            Write-Warn "Couldn't download $rel"
            exit 1
        }
    }
}

Get-BauerFile "personas/$persona/CLAUDE.md" $claudeMd

foreach ($skill in $skills) {
    $skillDir = Join-Path $skillsDir $skill
    if (Test-Path $skillDir) {
        $stamp = [int][double]::Parse((Get-Date -UFormat %s))
        Move-Item $skillDir "$skillDir.before-bauer.$stamp"
    }
    New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
    Get-BauerFile "personas/$persona/skills/$skill/SKILL.md" (Join-Path $skillDir "SKILL.md")
}

# --- Done ---
Write-Host ""
Write-Ok "All set!"
Write-Host ""
Write-Say "To start using Bauer with your local AI, run:"
Write-Host ""
Write-Say "    ccr code"
Write-Host ""
Write-Say "(this auto-starts the bridge and opens Claude Code on the local model)"
Write-Host ""
Write-Say "First-time tip — try asking..."
switch ($persona) {
    "business-owner" { Write-Say "    `"Help me draft a follow-up email to a client.`"" }
    "side-project"   { Write-Say "    `"What's the smallest useful thing I should ship this weekend?`"" }
    "freelancer"     { Write-Say "    `"Draft this week's status update for [client]. Notes: ...`"" }
}
Write-Host ""
Write-Say "📝  Note: open-source local models are slower and less capable than Claude."
Write-Say "    For complex tasks, consider switching to the Claude path:"
Write-Say "    https://bauerai.vercel.app/install.ps1"
Write-Host ""
