# Launch Posts — HN + Reddit

> Drafts. Read before posting and add a personal hook at the top so it doesn't read like an AI-written launch.

---

## Show HN

**Title**

```
Show HN: Receipts – a portable skill that forces AI coding agents to log and audit everything they do
```

**Body**

```
Hi HN,

I got tired of working on AI-generated codebases that have no memory. The agent edits files, swallows exceptions, leaves no trail, and the moment something breaks nobody can tell what changed, when, or why.

Receipts is a single skill package you drop into any AI coding agent (Claude Code, Cursor, Cline, Windsurf, Roo Code, OpenHands) that forces it to behave like a Principal Reliability Engineer + Codebase Historian at the same time.

What it does:

- Scans the repo before any change and classifies each file's observability (fully / partially / minimally / not observable)
- Maintains an append-only change ledger with timestamp, files affected, risk, validation, rollback notes
- Maintains a debug map mapping each flow to entrypoints, logs, failure points, repro steps, fix locations
- Maintains an incident log linking every bug to root cause, fix, and prevention
- Enforces a structured log schema with required fields and a stable error taxonomy (E_VAL_*, E_DEP_*, E_TMO_*, etc.)
- Hard rules: no silent failures, no swallowed exceptions, no print-only debugging, no async work without lifecycle logs, no state mutation without audit trail

Two modes:

- Remediation mode: existing repo — scans, generates baseline docs, then upgrades observability file by file
- Greenfield mode: new repo — enforces the rules from the first commit

Repo: https://github.com/Tramsnf/Receipts (MIT)

Includes drop-in installers for the major agents and language cookbooks for Node + pino, Python + structlog, and Go + slog.

Curious if anyone here has tried similar approaches with their agents. The hardest part for me has been getting the agent to consistently classify files and update the change ledger without being prompted every single task — solved that by making it part of the "definition of done" rather than a step you ask for. Open to PRs / critique.
```

---

## r/LocalLLaMA

**Title**

```
A portable skill that forces any AI coding agent to log, track, and audit everything (works with local models too)
```

**Body**

```
Frustrated with AI agents leaving no trail, swallowing exceptions, and producing codebases with no memory. So I packaged a skill that drops into Claude Code / Cursor / Cline / Windsurf / Roo Code / OpenHands and forces the agent to:

- scan the repo before changes
- classify each file's observability
- maintain an append-only change ledger
- maintain a debug map per flow
- enforce structured logs + error taxonomy
- treat missing logs / missing error handling as production bugs

Works with anything that has a system-prompt slot — including local models behind Cline or Roo Code.

Repo: https://github.com/Tramsnf/Receipts (MIT)

Anyone here running similar prompts on their local models? Curious what works and what doesn't for smaller context windows — I might add a "lite" variant if there's interest.
```

---

## r/ChatGPTCoding

**Title**

```
[Show] Receipts — a portable skill that forces your AI coding agent to log, track, and audit every change
```

**Body**

```
Built a skill package that drops into any AI coding agent and turns it from "vibe coder" into "Principal Reliability Engineer." It forces the agent to scan the repo first, classify each file's observability, maintain a change ledger + debug map + incident log, and treat missing logs / error handling as production bugs.

Drop-in installers for:

- Claude Code (~/.claude/skills/)
- Cursor (.cursorrules)
- Cline / Roo Code / Windsurf / OpenHands
- Any LLM with a system prompt slot

Plus language cookbooks for Node + pino, Python + structlog, Go + slog showing concrete patterns for correlation IDs, error classes, dependency call wrappers.

MIT licensed: https://github.com/Tramsnf/Receipts

Curious if anyone tries it — feedback welcome.
```

---

## r/programming

**Title**

```
Stop AI coding agents from leaving codebases with no memory: a portable skill that enforces logging, error handling, and audit trails
```

**Body**

```
Every "AI-generated" codebase I've inherited has the same disease: no audit trail, weak logs, swallowed exceptions, no way to tell what broke or why. The agent edited files, called it done, and moved on.

I packaged a portable skill that fixes this at the prompt level. It forces the agent to:

- scan the repo before changes
- classify each file's observability (fully / partially / minimally / not observable)
- maintain an append-only change ledger
- map every flow to its entrypoints, logs, and failure points
- log every bug to a root-cause incident file
- enforce a structured log schema and stable error taxonomy
- treat missing logs / missing error handling as production bugs, not nice-to-haves

It's not new science — it's just the SRE / postmortem / incident-response habits engineers already have, codified into the agent's operating contract.

MIT, single repo, install for whatever agent you use: https://github.com/Tramsnf/Receipts
```

---

## r/devops

**Title**

```
A portable skill that forces AI coding agents to write production-grade observability from the first line of code
```

**Body**

```
The thing I hate most about reviewing AI-generated services: no correlation IDs, no structured logs, no error taxonomy, generic try/catch eating exceptions, async work with zero lifecycle visibility.

Built a skill that forces any AI coding agent to satisfy a strict instrumentation contract on every change:

- structured logs at start / checkpoint / success / failure boundaries
- correlation IDs propagated through async trees
- stable error codes + error classes (E_VAL_*, E_AUTH_*, E_DEP_*, E_TMO_*, …)
- per-layer expectations for routes, services, data layer, jobs, dep calls, auth flows
- maintains a debug map and an incident log per repo

Works with Claude Code, Cursor, Cline, Windsurf, Roo Code, OpenHands. Cookbooks for Node + pino, Python + structlog, Go + slog included.

https://github.com/Tramsnf/Receipts (MIT)
```

---

## Posting tips

- Stagger posts by 2–4 hours so you can engage in comments on each before the next
- Reply to every comment in the first hour — HN and Reddit reward early engagement
- Don't post to all subs simultaneously — Reddit will flag cross-posts
- If a post gains traction, tweet about it from your X account to compound
- Add a personal hot-take at the top of each draft before posting; never post the draft as-is
