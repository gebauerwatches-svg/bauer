# Bauer installer for Windows
# Sets up Claude Code with a sensible default config for non-developers.
#
# Run with:    iwr https://bauerai.vercel.app/install.ps1 | iex
# Local test:  $env:ROCKY_LOCAL = (Get-Location).Path; .\install.ps1

$ErrorActionPreference = "Stop"

function Write-Say  { param([string]$msg) Write-Host "  $msg" }
function Write-Ok   { param([string]$msg) Write-Host "  ✅  $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  ⚠️   $msg" -ForegroundColor Yellow }

# --- Welcome ---
Write-Host ""
Write-Say "🧱  Welcome to Bauer"
Write-Host ""
Write-Say "This sets up Claude Code on your computer."
Write-Say "Takes about a minute. You can stop anytime with Ctrl+C."
Write-Host ""
Start-Sleep -Seconds 1

# --- Check Node.js ---
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Warn "Node.js isn't installed yet."
    Write-Host ""
    Write-Say "Node.js is a small piece of software that Claude Code needs to run."
    Write-Say "Download it from:  https://nodejs.org/   (pick the LTS version)"
    Write-Host ""
    Write-Say "Once installed, run this Bauer command again."
    exit 1
}

# --- Install Claude Code if missing ---
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Say "📦  Installing Claude Code..."
    try {
        & npm install -g "@anthropic-ai/claude-code" 2>&1 | Out-Null
    } catch {
        Write-Warn "The install didn't work. Try running PowerShell as Administrator."
        exit 1
    }
    Write-Ok "Claude Code installed"
    Write-Host ""
}

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

# --- Skills per persona ---
$skills = switch ($persona) {
    "business-owner" { @("customer-message", "proposal-or-quote", "marketing-copy", "build-agent") }
    "side-project"   { @("draft-content", "launch-copy", "scope-and-prioritize", "build-agent") }
    "freelancer"     { @("client-update", "scope-and-estimate", "scope-creep-response", "build-agent") }
}

# --- Destination ---
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

# Backup existing CLAUDE.md
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) {
    $stamp = [int][double]::Parse((Get-Date -UFormat %s))
    $backup = "$claudeMd.before-bauer.$stamp"
    Move-Item $claudeMd $backup
    Write-Say "(Backed up your existing CLAUDE.md to: $backup)"
}

# --- Source: local file copy or remote download ---
$rockyBase  = if ($env:ROCKY_BASE) { $env:ROCKY_BASE } else { "https://bauerai.vercel.app" }
$rockyLocal = $env:ROCKY_LOCAL

function Get-RockyFile {
    param([string]$rel, [string]$dest)
    if ($rockyLocal) {
        Copy-Item -Path (Join-Path $rockyLocal $rel) -Destination $dest -Force
    } else {
        try {
            Invoke-WebRequest -Uri "$rockyBase/$rel" -OutFile $dest -UseBasicParsing
        } catch {
            Write-Warn "Couldn't download $rel"
            Write-Warn "Check your internet connection and try again."
            exit 1
        }
    }
}

# --- Download CLAUDE.md ---
Get-RockyFile "personas/$persona/CLAUDE.md" $claudeMd

# --- Download each skill ---
foreach ($skill in $skills) {
    $skillDir = Join-Path $skillsDir $skill
    if (Test-Path $skillDir) {
        $stamp = [int][double]::Parse((Get-Date -UFormat %s))
        Move-Item $skillDir "$skillDir.before-bauer.$stamp"
    }
    New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
    Get-RockyFile "personas/$persona/skills/$skill/SKILL.md" (Join-Path $skillDir "SKILL.md")
}

# --- Done ---
Write-Host ""
Write-Ok "All set!"
Write-Host ""
Write-Say "To start using Claude, type:"
Write-Host ""
Write-Say "    claude"
Write-Host ""
Write-Say "And press Enter."
Write-Host ""
Write-Say "First-time tip — try asking Claude something like..."
switch ($persona) {
    "business-owner" { Write-Say "    `"Help me draft a follow-up email to a lead I haven't heard back from in two weeks.`"" }
    "side-project"   { Write-Say "    `"I have 3 hours this Saturday. What's the smallest useful thing I should ship?`"" }
    "freelancer"     { Write-Say "    `"Draft this week's status update for [client]. Notes: shipped the homepage, blocked on copy approval.`"" }
}
Write-Host ""
