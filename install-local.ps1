# Bauer LOCAL installer for Windows
# Sets up Bauer with an OPEN-SOURCE local AI (via Ollama) instead of Claude.
#
# Run with:    iwr https://bauerai.vercel.app/install-local.ps1 | iex

$ErrorActionPreference = "Stop"

function Write-Say  { param([string]$msg) Write-Host "  $msg" }
function Write-Ok   { param([string]$msg) Write-Host "  ✅  $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  ⚠️   $msg" -ForegroundColor Yellow }

# --- Helper: locale-safe Unix timestamp ---
function Get-Stamp { [DateTimeOffset]::Now.ToUnixTimeSeconds() }

# --- Helper: npm install -g with user-prefix fallback (admin-free) ---
function Install-NpmGlobal {
    param([string]$pkg)
    & npm install -g $pkg 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { return $true }

    $userPrefix = Join-Path $env:USERPROFILE ".npm-global"
    if (-not (Test-Path $userPrefix)) {
        New-Item -ItemType Directory -Force -Path $userPrefix | Out-Null
    }
    & npm config set prefix $userPrefix 2>$null | Out-Null
    & npm install -g $pkg 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $env:PATH = "$userPrefix;$env:PATH"
        Write-Warn "npm global directory was set to $userPrefix (system one wasn't writable)."
        Write-Say "    Add this to your PowerShell profile for new terminals:"
        Write-Say "        `$env:PATH = `"$userPrefix;`$env:PATH`""
        return $true
    }
    return $false
}

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
if ($ready -notmatch "^[Yy]") { Write-Say "Bye!"; return }
Write-Host ""

# --- Check Ollama ---
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Warn "Ollama isn't installed yet."
    Write-Host ""
    Write-Say "Manual install needed on Windows:"
    Write-Say "    1. Visit:  https://ollama.com/download"
    Write-Say "    2. Download and run OllamaSetup.exe"
    Write-Say "    3. Re-run this Bauer script when done"
    return
}

# --- Start Ollama service (Windows: usually starts automatically with the installer) ---
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
    & ollama pull $model
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Model download failed. Check your internet and try again."
        return
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
    return
}

# --- Install Claude Code ---
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Say "📦  Installing Claude Code..."
    if (-not (Install-NpmGlobal "@anthropic-ai/claude-code")) {
        Write-Warn "Install failed. Try a new PowerShell as Administrator, or manually:"
        Write-Say "    npm config set prefix `"$env:USERPROFILE\.npm-global`""
        Write-Say "    npm install -g @anthropic-ai/claude-code"
        return
    }
    Write-Ok "Claude Code installed"
    Write-Host ""
}

# --- Install the bridge ---
if (-not (Get-Command ccr -ErrorAction SilentlyContinue)) {
    Write-Say "🔗  Installing the Ollama bridge (claude-code-router)..."
    if (-not (Install-NpmGlobal "claude-code-router")) {
        Write-Warn "Bridge install failed. Manual install:"
        Write-Say "    npm install -g claude-code-router"
        Write-Say "Continuing — we'll set up the config; you can install the bridge later."
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

$skills = @(switch ($persona) {
    "business-owner" { "customer-message"; "proposal-or-quote"; "marketing-copy"; "build-agent" }
    "side-project"   { "draft-content"; "launch-copy"; "scope-and-prioritize"; "build-agent" }
    "freelancer"     { "client-update"; "scope-and-estimate"; "scope-creep-response"; "build-agent" }
})

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) {
    $stamp = Get-Stamp
    Move-Item $claudeMd "$claudeMd.before-bauer.$stamp"
}

$bauerBase  = if ($env:BAUER_BASE)  { $env:BAUER_BASE }  elseif ($env:ROCKY_BASE)  { $env:ROCKY_BASE }  else { "https://bauerai.vercel.app" }
$bauerLocal = if ($env:BAUER_LOCAL) { $env:BAUER_LOCAL } else { $env:ROCKY_LOCAL }

function Get-BauerFile {
    param([string]$rel, [string]$dest)
    if ($bauerLocal) {
        Copy-Item -Path (Join-Path $bauerLocal $rel) -Destination $dest -Force
    } else {
        try {
            Invoke-WebRequest -Uri "$bauerBase/$rel" -OutFile $dest -UseBasicParsing
        } catch {
            Write-Warn "Couldn't download $rel"
            throw
        }
    }
}

try {
    Get-BauerFile "personas/$persona/CLAUDE.md" $claudeMd

    foreach ($skill in $skills) {
        $skillDir = Join-Path $skillsDir $skill
        if (Test-Path $skillDir) {
            $stamp = Get-Stamp
            Move-Item $skillDir "$skillDir.before-bauer.$stamp"
        }
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
        Get-BauerFile "personas/$persona/skills/$skill/SKILL.md" (Join-Path $skillDir "SKILL.md")
    }
} catch {
    return
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
