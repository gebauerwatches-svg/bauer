# Bauer

> **AI you install. Agents you build.**

A one-command installer that sets up Claude Code with a curated config tuned for non-developers — small business owners, side project runners, indie makers — and a built-in `build-agent` skill that walks you through designing custom AI agents in plain English.

🌐 [**bauerai.vercel.app**](https://bauerai.vercel.app)

## Install

**Mac / Linux:**
```bash
curl -sSL https://bauerai.vercel.app/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr https://bauerai.vercel.app/install.ps1 | iex
```

## What it does

When you run the installer, Bauer:

1. Installs Claude Code (if not already installed)
2. Asks which persona fits your work
3. Drops a curated `CLAUDE.md` and 4 role-specific skills into `~/.claude/`
4. Backs up any existing config first — nothing is overwritten silently

## Personas

| | | |
|---|---|---|
| 🏪 | **Small business owner** | Tuned for customer comms, proposals/quotes, and marketing copy |
| 🚀 | **Side project runner** | Tuned for drafting content, launch copy, and "what should I ship next?" |

Both personas ship with the same 4 skills:

- `[role-skill-1]`, `[role-skill-2]`, `[role-skill-3]` — daily-task helpers tuned for the persona
- `build-agent` — walks you through designing a custom agent in plain English (purpose → access → model → guardrails → file)

## What you'll need

- A Mac or Windows computer
- A [Claude Pro subscription](https://claude.ai) ($20/mo, recommended) **or** an open-source local model via [Ollama](https://ollama.com) (free, more setup)
- Node.js (the installer will tell you if it's missing)

## Project layout

```
bauer-project/
├── index.html          ← landing page
├── about.html          ← founder story
├── style.css
├── script.js
├── install.sh          ← Mac/Linux installer
├── install.ps1         ← Windows installer
└── personas/
    ├── business-owner/
    │   ├── CLAUDE.md
    │   └── skills/{customer-message, proposal-or-quote, marketing-copy, build-agent}/SKILL.md
    └── side-project/
        ├── CLAUDE.md
        └── skills/{draft-content, launch-copy, scope-and-prioritize, build-agent}/SKILL.md
```

The site, install scripts, and persona files all deploy from the project root as static files on Vercel.

## Why "Bauer"?

"Bauer" is German for *builder*. It's also a piece of the founder's last name (Gebauer). [Read the full story](https://bauerai.vercel.app/about.html).

## Built by

[Liam](https://bauerai.vercel.app/about.html), 14, Steamboat Springs, Colorado.

## License

[MIT](LICENSE) — use, fork, modify, or redistribute freely.
