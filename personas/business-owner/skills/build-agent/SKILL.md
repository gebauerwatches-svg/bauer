---
name: build-agent
description: Use when the user wants to build, design, create, or set up a new AI agent or automation for a specific task. Walks them through purpose, access, model choice, risks, and guardrails — then writes the agent file.
---

# Building a new agent

Your job is to walk the user through designing an agent in plain English — covering purpose, access, model choice, risks, and guardrails — then write the skill file that makes it real.

Move one phase at a time. Ask one question at a time, never a list.

---

## Phase 1 — What is the agent?

Get clear on the basics:

1. **The goal.** "What should this agent do for you, in one sentence?"
2. **The trigger.** "When should it run?
   - On-demand (you ask it: 'check my inbox')
   - Scheduled (every morning at 9am)
   - Reactive (when an email arrives)"
3. **The output.** "Where should the result go? Reply in chat, write a file, send an email, post somewhere?"

Skip questions where the answer is obvious from what they've already said.

---

## Phase 2 — What does it need access to?

This is where most agents go wrong. Walk through it carefully.

Ask: "What does this agent need to read or interact with? Common ones:"
- 📧 Email (Gmail, Outlook)
- 📁 Files on your computer
- ☁️ Cloud storage (Google Drive, Dropbox)
- 📅 Calendar
- 💬 Slack / messaging
- 🌐 The web (search, scrape)
- 📊 Spreadsheets
- 🤖 Other AI tools

For EACH thing they name, ask: **"What level of permission?"**

Three levels — explain in plain English:
- **Read-only** — can see, can't change. (Recommended starting point.)
- **Read + create** — can see, can add new things, but can't modify or delete existing items.
- **Full access** — can see, create, modify, delete. (Risky; only if necessary.)

For Google Drive specifically, this is the right shape of question:
> *"Read-only — it can look at your files but can't change them. Read + create — can also save new files (good for an agent that writes summaries to a folder). Full access — can also edit and delete; only pick this if you fully trust it not to mess up."*

Write down each tool + permission level clearly. These become hard rules later.

---

## Phase 3 — Model and hosting

Two real options. Be honest about the tradeoffs.

**Closed-source (recommended for most people)**
- Anthropic's Claude (what Bauer installs by default)
- ~$20/month for Claude Pro — predictable, fast, capable
- Hosted by Anthropic — your prompts go to their servers (they don't train on it)
- Best for: most people, complex tasks, "I just want it to work"

**Open-source (free but more setup)**
- Local model via Ollama (e.g., Llama 3.3 or Mistral)
- Free after setup; runs entirely on the user's computer
- Slower, less capable on complex/multi-step tasks
- Good for: privacy-sensitive work, no monthly cost, full control
- Setup the user will need: install Ollama (ollama.com), run `ollama pull llama3.3`, then point Bauer at it (note: this is currently manual — fully automated open-source install is on the roadmap)

Ask: **"Which path?**
1. **Claude Pro** ($20/mo) — easiest, most capable.
2. **Open-source local model** — free, more setup, more privacy."

If user picks open-source:
- Note that the agent's instructions should be simpler (smaller models handle complex chains less well)
- Give them the Ollama setup link
- Be honest: "Right now Bauer's installer doesn't auto-configure local models — you'll wire it up manually. I can write the instructions."

---

## Phase 4 — Risks and guardrails

This is the most important phase. Don't skip it.

Ask in order, one at a time:

### 1. "What's the worst thing that could happen if this agent malfunctions?"

Wait for their answer. Common worst cases:
- Sending an email to the wrong person
- Deleting important files
- Spending money the user didn't intend
- Sharing private info externally
- Replying to a customer with wrong info

### 2. "What hard rules should this agent NEVER break?"

Help them list 3-5 specific rules. Examples by domain:
- *Email:* "Never send without showing me first." "Never reply to anyone outside my contacts list."
- *Files:* "Never delete or modify existing files." "Never write outside this folder: ~/Documents/agent-output."
- *Money:* "Never spend more than $10 in any one action." "Never make purchases at all."
- *Communication:* "Always include a 'sent by AI' line." "Never use my full name in outbound messages."
- *Data:* "Never share anything outside this folder." "Never include customer phone numbers in outputs."

### 3. "What should it do if it's unsure?"

Default best answer: **"Ask me before acting."** This is the most important guardrail. Make sure it's in their list.

### 4. Honest limitations

Tell them what the agent can't do well:
- It doesn't have memory between runs unless you set up a way to give it context (e.g., a notes file)
- It can be wrong on complex math, real-time info, or things it wasn't trained on
- It can hallucinate confidently — guardrails are how you catch this

---

## Phase 5 — Show the design

Output a clean summary of everything decided so far:

```
Agent: [short name]

🎯 Purpose: [one sentence]
⏰ When it runs: [trigger]
📥 What it accesses:
   - [tool 1]: [permission level]
   - [tool 2]: [permission level]
📤 Output: [where result goes]
🤖 Model: [Claude Pro / Ollama + Llama3.3]

🛑 Hard rules (will never break):
- [rule 1]
- [rule 2]
- [rule 3]
- If unsure → ask the user before acting

⚠️ Known limitations:
- [one or two — e.g., "doesn't have access to your CRM yet", "can be slow on long emails"]
```

Ask: **"Does this look right? Want to change anything before I build it?"**

---

## Phase 6 — Build the agent

Once the user confirms:

### Write the skill file

Save to `~/.claude/skills/[agent-name]/SKILL.md`. Use kebab-case based on purpose (e.g., `morning-inbox-summary`, `customer-faq-replier`, `weekly-content-planner`).

Format:

```markdown
---
name: [agent-name]
description: [when this skill should trigger — natural-language phrase]
---

# [Agent Name]

## Purpose
[one sentence]

## Trigger
When the user says: "[trigger phrase]"

## What I do
[step-by-step instructions in plain English]

## Tools I use
- [tool 1] — [permission level: read-only / read+create / full]
- [tool 2] — [permission level]

## Hard rules (NEVER break these)
- [rule 1]
- [rule 2]
- [rule 3]

## If I'm unsure
Ask the user before acting.

## Limitations
- [limitation 1]
- [limitation 2]
```

### Tell the user how to use it

Wrap with a clear handoff:

> Done! Your agent is saved at `~/.claude/skills/[agent-name]/SKILL.md`.
>
> **To use it:** just say *"[trigger phrase]"* in chat.
>
> **To edit:** open the file and change anything you want — the rules, the steps, the tools.
>
> **To disable:** delete the folder.
>
> **Try it now:** [give one specific example prompt]

### Scheduled or reactive triggers

If the agent needs to run on a schedule (like "every morning") or react to events (like "when a new email arrives"):

> *"Right now this runs when you ask it directly. For scheduled runs, you'll need to set up a cron job (Mac/Linux) or Task Scheduler (Windows). For reactive triggers, we'd need a watcher script. Want me to write the instructions for either?"*

Be honest about limits — don't pretend you can do things that need additional setup.

---

## Don't

- **Don't skip the guardrails phase.** Most agents fail because they did something the user didn't anticipate.
- **Don't pretend the agent has access to tools you haven't actually configured.** If the user said "read my email" but no email integration is set up, name that gap clearly.
- **Don't generate a "perfect" agent that does 10 things.** Start with 1 thing it does well.
- **Don't quietly skip permissions questions.** "It needs access to my Drive" is not enough — always ask the read/create/full question.
