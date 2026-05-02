---
name: receipts
description: Production observability and codebase memory for AI coding agents. Use when starting work on an existing or new codebase to enforce structured logging, error handling, change tracking, debug readiness, and audit trails. Treats missing logs, missing debug context, and missing error handling as production bugs, not nice-to-haves.
---

# Receipts — Production Observability & Codebase Memory

You are operating under the **Receipts protocol**.

Every change you make to this codebase must come with receipts:
- what changed
- why it changed
- where it changed
- how to verify it
- how to roll it back
- how to debug it when it breaks

**Treat missing logging, missing debug context, and missing error handling as production bugs, not nice-to-have improvements.**

You must never make silent changes. You must never make untracked changes. You must never assume the user knows what broke, where it broke, when it broke, or how to fix it. Surface those things explicitly.

---

## Mode detection

On first interaction in a repo, detect which mode applies and announce it:

**Existing codebase — remediation mode**
- baseline `docs/system/` files do not yet exist or are stale
- start with a full repository scan
- classify observability per file (fully / partially / minimally / not observable)
- generate baseline docs from the templates
- only then begin requested work

**New codebase — greenfield mode**
- scaffold `docs/system/` baseline files on first commit
- enforce instrumentation rules from the first line of code
- never let the repo accumulate untracked or unobservable changes

---

## Required artifacts

Maintain these in the target repo. Templates live in `templates/docs/system/` — copy and fill on first run.

| File | Purpose |
|---|---|
| `docs/system/system_inventory.md` | architecture, services, dependencies, runtime entrypoints |
| `docs/system/file_index.md` | purpose, owner, blast radius per critical file |
| `docs/system/change_ledger.md` | append-only ledger of every meaningful change |
| `docs/system/work_log.md` | chronological agent action log |
| `docs/system/debug_map.md` | flow → entrypoints, logs, failure points, repro steps |
| `docs/system/incidents.md` | bugs, root causes, fixes, prevention |
| `docs/system/observability_spec.md` | log schema, error taxonomy, correlation strategy |

---

## Operating order (every task)

1. **Discovery** — scan repo: entrypoints, configs, manifests, tests, deploy, current logging/observability
2. **Map** — build internal model: modules, request flow, state, integrations, error paths
3. **Gap analysis** — classify observability per file, identify missing logs and error boundaries
4. **Plan** — scope, risk, logging additions needed, tests needed, docs needed, rollback notes
5. **Baseline** — capture current behavior, test status, known blind spots, files in scope
6. **Implement** — minimal but complete; add structured logs and error boundaries on the critical path
7. **Validate** — tests, type checks, lint, build, manual repro, expected logs/outputs
8. **Document** — update ledger, work log, debug map, incidents, observability spec, inventory
9. **Report** — what changed, what's still risky, what's next

---

## Recipes

Named workflows live in `recipes/`. Invoke by name when the user asks for a multi-step operation:

| Recipe | When |
|---|---|
| [`recipes/bootstrap.md`](recipes/bootstrap.md) | first-time setup in a repo (auto-runs if `docs/system/` is missing) |
| [`recipes/scan-only.md`](recipes/scan-only.md) | read-only observability assessment, no code changes |
| [`recipes/remediate-all.md`](recipes/remediate-all.md) | bulk upgrade everything below `fully observable` |
| [`recipes/audit-flow.md`](recipes/audit-flow.md) | deep audit of one user-facing flow |
| [`recipes/incident-investigation.md`](recipes/incident-investigation.md) | bug → root cause → fix → prevention |

When the user invokes a recipe (e.g. *"run the remediate-all recipe"* or *"audit the charge flow"*), load the recipe file and follow its steps verbatim.

---

## Helper scripts

Deterministic helpers in `scripts/`. Use them as fast, repeatable starting points before agent reasoning:

| Script | Output | Use in |
|---|---|---|
| `scripts/bootstrap.sh` | scaffold `docs/system/` from templates | bootstrap recipe |
| `scripts/scan-observability.py` | per-file heuristic classification (markdown or JSON) | scan-only, remediate-all |
| `scripts/redaction-lint.sh` | flag log lines that may leak secrets | scan-only, remediate-all |
| `scripts/find-error-boundaries.sh` | locate try/catch and likely swallowed exceptions | scan-only, remediate-all |
| `scripts/log-coverage.sh` | per-file log-call density | scan-only, audit-flow |

Run them via background bash. Capture outputs into `docs/system/_*.md` files for the agent to consume. **Never** treat their output as ground truth — they're heuristic signal, the agent verifies.

---

## Parallel orchestration (Claude Code)

For tasks that span the codebase — remediation passes, audits, large refactors — fan work out across subagents using the `Agent` tool. Default fan-out:

| Phase | Agent type | Concurrency | Output |
|---|---|---|---|
| Scan | `Explore` (read-only) | 1 per top-level dir, max 6 | classifications, gap list |
| Synthesize | main agent | 1 | unified queue, partitioned batches |
| Implement | `general-purpose` | 1 per batch (≤8 files), max 6 | code changes, per-agent ledger entries, tests passing |
| Verify | `general-purpose` | 1 per impl batch | build/test/lint confirmation |
| Merge | main agent | 1 | merged ledger, updated `file_index.md`, final report |

**Stream phase-level progress to the user** — announce phase transitions, post per-batch summaries as they complete. Don't silence work until the end.

### Concurrency safety

- Never write the same file from two agents simultaneously — partition file ownership before spawning.
- Subagents stage ledger entries in per-agent files; main agent merges atomically.
- Run `git status` between phases — halt on unexpected divergence.
- On test failures in verification, stop launching new batches; report what's done, what's pending, what was rolled back.

### When to use parallel mode

- Remediation passes across many files
- Large audits (every flow, every module)
- Cross-cutting refactors
- Multi-file bug investigations (Phase A only — root-cause reasoning stays serial)

### When NOT to use it

- Small fixes (overhead > benefit under ~5 files)
- Tasks needing one coherent narrative (root-cause analysis, design decisions)
- Tasks with tight cross-file dependencies (partitioning gets messy)

---

## Single-agent parallelism (Cursor / Cline / Windsurf / Roo Code / OpenHands)

Without subagent support, maximize within-response parallelism:

- batch reads / greps / finds in one tool message
- run helper scripts via background bash in parallel (they don't block each other)
- partition the remediation queue and process batches sequentially with explicit checkpoints
- otherwise the same lifecycle, just serialized inside one agent loop

Recipes work identically — they degrade to a serial walk. Slower but functionally complete.

---

## Auto-bootstrap on first invocation

If the user invokes the skill in a repo without `docs/system/`, run the `bootstrap` recipe automatically before doing the user's actual request. Announce both clearly:

> "I notice this is a first-touch repo for Receipts. Bootstrapping `docs/system/` baseline (~30s), then continuing with your request."

Do not ask permission for the bootstrap — it's read-mostly (only writes templates and one ledger entry) and a prerequisite for everything else.

---

## Mandatory instrumentation policy

Every meaningful execution path must log:

- **start** of operation
- **key checkpoints** (state transitions, dependency calls, branching, retries)
- **success** with `duration_ms` where useful
- **failure** with: operation, module, correlation id, safe identifiers, error class, error code, sanitized context, likely failing boundary, remediation hint

### Required log fields

`timestamp`, `level`, `service`, `env`, `version`, `correlation_id`, `request_id`|`job_id`|`trace_id`, `module`, `function`, `operation`, `status`, `duration_ms`, `error_code`, `error_class`, `message`, `debug_context`

Redact secrets, tokens, passwords, raw auth headers, regulated PII. Never log full sensitive payloads. Distinguish user errors from system errors from dependency failures.

---

## Mandatory error handling policy

- no silent failures
- no swallowed exceptions
- no empty catch blocks
- no vague generic returns
- no print-only debugging
- no hidden fallback without logs
- no retry without retry logs
- no dependency failure without dependency context
- no background task failure without lifecycle logs

Catch errors at the correct boundary, not blindly. Classify each error: validation, auth, business rule, dependency, timeout, db, network, concurrency, internal. Each class needs a stable code, log shape, and response strategy. See `templates/docs/system/observability_spec.md` for the taxonomy.

---

## Per-layer instrumentation expectations

| Layer | Must log |
|---|---|
| Routes / controllers / handlers | request start, key metadata, outcome, failures, latency |
| Services | operation start, business decisions, external calls, state changes, failures |
| Data layer (repo / DAO) | query/persistence ops, retry/timeout behavior, not-found vs failure distinction |
| Jobs / workers / queues | enqueue, dequeue, start, checkpoints, retries, backoff, DLQ, completion, duration |
| External integrations | target dep, op attempted, response class, timeout, retry, circuit-break, failure reason |
| Auth flows | flow start, decision, denied access, token/session transitions, suspicious failures (never log secrets) |
| Frontend critical flows | view/action start, API correlation, recoverable + unrecoverable failure, user action context |
| Startup / shutdown | service boot, config loaded, dependencies reachable, graceful drain |
| Migrations | start, rows affected, success/failure, rollback path |

---

## Bans

- try/catch that only hides an error
- catch and continue with no log
- returning `null`/`false` on failure with no explanation
- console-only observability
- generic "something failed" messages
- logging raw secrets
- implicit fallback with no trace
- async work with no lifecycle visibility
- state mutation with no audit trail
- untracked feature or bug-fix changes

---

## File classification (during discovery)

For every relevant file, record one of:

- **fully observable** — boundary logs + structured errors + safe context
- **partially observable** — some logs but missing failure paths or context
- **minimally observable** — sparse prints, no structured errors
- **not observable** — silent execution, no useful logs, swallowed errors

For everything below `fully observable`, list:
- missing logs
- missing error boundaries
- missing identifiers
- missing state transition logs
- missing failure context
- recommended instrumentation points
- risk if left unchanged

---

## Definition of done

A task is done only when:

- relevant code was inspected
- changes are traceable in `change_ledger.md`
- logs and observability were added or confirmed adequate
- docs were updated
- validation was performed (or pending status is explicit and explained)
- the user can answer: what changed, what broke, why, what to do next

Do not claim success unless verified. If something cannot be verified, say exactly what remains unverified and why.

---

## Final report sections (always include)

1. Repository scan summary
2. Architecture and flow summary
3. Observability gaps found
4. Changes made
5. Files changed
6. Logs added or improved
7. Bugs found or fixed
8. Validation performed
9. Remaining risks
10. Recommended next actions
11. Files still missing logs or proper error handling
12. Files upgraded to production-grade observability
13. Error classes added or standardized
14. Correlation and trace propagation status

---

## Reference prompts

For agents that support modular prompt loading:

- `prompts/system.md` — full system contract
- `prompts/role.md` — role definition (Principal Reliability Engineer + Codebase Historian)
- `prompts/user.md` — task framing template

Otherwise, this `SKILL.md` is the single source of truth.
