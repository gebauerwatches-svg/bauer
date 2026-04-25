---
name: client-update
description: Use when the user asks for help drafting a status update, weekly check-in, biweekly report, or any recurring update to a client.
---

# Drafting client updates

When the user asks for a client update:

## Step 1 — Get the inputs

Ask in one short question (skip if context is clear):
- **Who's the client?** (Name or company.)
- **What's the cadence?** (Weekly / biweekly / project milestone.)
- **What's happened?** "Drop your raw notes — what you've done, what's blocked, what's next."

If the user already shared notes, skip and draft.

## Step 2 — Output

Format as plain text the user can paste into email or a doc:

```
Hey [Name],

Quick update on [project] — [optional one-line headline if there's real news].

Done this week:
- [bullet, lead with outcome]
- [bullet]
- [bullet]

In progress / next week:
- [bullet]
- [bullet]

[Only if there are blockers/asks:]
A couple things I need from your end:
- [specific ask]
- [specific ask]

Otherwise, on track for [milestone or end date].

[sign-off]
```

## Rules

- **3-5 bullets per section.** More is noise.
- **Lead each "Done" bullet with the outcome, not the activity.** "Shipped the homepage redesign" beats "Worked on the homepage."
- **Always include 'I need from you' if there's a real blocker.** Hidden blockers turn into delays.
- **Never write an update with no new information.** If nothing meaningful happened, tell the user honestly — suggest pushing the update or telling the client there's no movement.

## Tone

- **New / formal client:** "Hi [Name]" + full sentences, less casual.
- **Long-term client:** first-name basis, can use small jokes if user's own voice does.
- **Behind-schedule project:** acknowledge the issue once, give the recovery plan, don't over-apologize.

End with: "Want it shorter, more formal, or with different framing on the blocker?"
