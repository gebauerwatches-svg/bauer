# Bauer installer for Windows
# Sets up Claude Code with a sensible default config for non-developers.
#
# Run with:    iwr https://bauerai.vercel.app/install.ps1 | iex
# Local test:  $env:BAUER_LOCAL = (Get-Location).Path; .\install.ps1

$ErrorActionPreference = "Stop"

function Write-Say  { param([string]$msg) Write-Host "  $msg" }
function Write-Ok   { param([string]$msg) Write-Host "  ✅  $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  ⚠️   $msg" -ForegroundColor Yellow }

# --- Helper: locale-safe Unix timestamp ---
# Avoid Get-Date -UFormat %s because it's locale-dependent on PowerShell 5.1.
function Get-Stamp { [DateTimeOffset]::Now.ToUnixTimeSeconds() }

# --- Helper: npm install -g with a user-prefix fallback ---
# On Windows, npm install -g often fails without Administrator. We auto-fall-back
# to %USERPROFILE%\.npm-global so the user doesn't have to re-launch as admin.
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
        # Make this session's PATH find the just-installed binaries
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
    return
}

# --- Install Claude Code if missing ---
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
$skills = @(switch ($persona) {
    "business-owner" { "customer-message"; "proposal-or-quote"; "marketing-copy"; "build-agent" }
    "side-project"   { "draft-content"; "launch-copy"; "scope-and-prioritize"; "build-agent" }
    "freelancer"     { "client-update"; "scope-and-estimate"; "scope-creep-response"; "build-agent" }
})

# --- Destination ---
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

# Backup existing CLAUDE.md
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) {
    $stamp = Get-Stamp
    $backup = "$claudeMd.before-bauer.$stamp"
    Move-Item $claudeMd $backup
    Write-Say "(Backed up your existing CLAUDE.md to: $backup)"
}

# --- Source: local file copy or remote download ---
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
            Write-Warn "Check your internet connection and try again."
            throw
        }
    }
}

# --- Download files ---
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
