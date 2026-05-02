# Launch Tweet Thread

> 8 tweets, each under 280 chars. Post as a thread. Pin the first tweet.

---

**1/**
Most "AI-coded" apps don't have receipts.

No audit trail. Weak logs. Silent failures. Nobody knows what broke, when, or why.

I built a skill that fixes this — drop it into your AI coding agent and your codebase suddenly has memory.

→ github.com/Tramsnf/Receipts

---

**2/**
The problem with vibe-coded systems:

→ no change ledger
→ no debug map
→ no incident log
→ no observability classification per file
→ exceptions get swallowed
→ "it just stopped working" with no trail

Unmaintainable the second the original author moves on.

---

**3/**
Receipts forces any AI coding agent to behave like a Principal Reliability Engineer + Codebase Historian — at the same time.

Before any change:
→ scan the repo
→ build a system map
→ classify each file's observability
→ generate baseline docs

Then it implements.

---

**4/**
On every task it maintains:

📒 change_ledger.md — append-only log
🗺 debug_map.md — flows → logs → failure points → repro
🚨 incidents.md — bugs → root cause → prevention
📊 observability_spec.md — log schema + error taxonomy
🧭 system_inventory.md — architecture + deps

---

**5/**
Hard rules baked into the prompt:

❌ no silent failures
❌ no swallowed exceptions
❌ no print-only debugging
❌ no hidden fallbacks
❌ no async work without lifecycle logs
❌ no state mutation without audit trail
❌ no bug fix without root cause notes

---

**6/**
The diff between vibe code and Receipts code:

❌ "It just stopped working last night, no idea why."

✅ "Failure at services/billing.charge, error E_DEP_STRIPE_TIMEOUT, correlation_id req_a8f2…, retry 3/3. Repro at debug_map.md#charge-flow. Fix tracked in ledger 2026-05-02-014."

---

**7/**
Works on every major AI coding agent:

→ Claude Code (~/.claude/skills/)
→ Cursor (.cursorrules)
→ Cline (custom instructions)
→ Windsurf (.windsurfrules)
→ Roo Code (custom mode)
→ OpenHands (.openhands/microagents/)
→ Any LLM with a system-prompt slot

---

**8/**
Free. MIT. Single repo. Drop-in installers + cookbooks for Node, Python, and Go included.

Treats missing logs, missing debug context, and missing error handling as production bugs — not nice-to-haves.

Star, fork, ship code that explains itself.

→ github.com/Tramsnf/Receipts

---

## Variants for individual posts (no thread)

### Hook 1 — provocative

> Your "AI-built" app has no receipts.
>
> No audit trail. No incident log. No correlation IDs. Exceptions silently swallowed. "It just stopped working" with zero forensic data.
>
> I packaged a fix as a portable skill: github.com/Tramsnf/Receipts

### Hook 2 — engineering-first

> Built a skill that forces AI coding agents to behave like SREs:
>
> - scan repo before changes
> - classify each file's observability
> - maintain a change ledger + debug map + incident log
> - enforce structured logs and a stable error taxonomy
>
> github.com/Tramsnf/Receipts (MIT)

### Hook 3 — meme-y

> AI agents that ship with receipts.
>
> Because "vibe-coded" should not mean "untraceable."
>
> github.com/Tramsnf/Receipts
