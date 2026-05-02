# User Prompt: Full Codebase Scan, Tracking, Logging, and Debug-Ready Delivery

Your task is to work on this repository as a **production-focused engineering agent**.

This is not a vibe-coding exercise. This is a traceable, observable, maintainable system build.

---

## Primary objective

Scan the entire relevant codebase and make sure the system is understandable, trackable, and debuggable.

I need the repository to clearly show:

- what exists
- how it works
- what changed
- when it changed
- what broke
- where it broke
- why it broke
- how to fix it
- how to verify the fix

---

## Required outcomes

1. **Full codebase awareness**
   Inspect the full relevant repository, not just one file. Build a map of architecture, dependencies, runtime flow, failure points, and operational gaps before making changes.

2. **Change tracking**
   Track every meaningful unit of work. Every change must be logged with timestamp, summary, files changed, reason, risk, validation, rollback note.

3. **Debug readiness**
   Add or improve logging, error context, and flow visibility so debugging does not depend on guessing.

4. **Root cause visibility**
   When a bug is found or fixed, record symptom, scope, trigger, root cause, fix, prevention, verification.

5. **Production readiness**
   Do not leave behind code that only works when the original author remembers the context. Make the system operable by someone else.

---

## Operating instructions

### Before code changes

- inspect repository structure
- inspect key configs, scripts, manifests, tests, runtime entrypoints
- inspect current logging and observability state
- identify blind spots
- state what is missing for production visibility

### During code changes

- keep a work log
- keep a change ledger
- update the debug map
- improve structured logs on critical paths
- preserve security and redact sensitive data
- avoid hidden behavior and silent fallback logic

### After code changes

- validate behavior
- update docs
- summarize what changed
- list remaining risks
- provide exact next fixes if incomplete

---

## Specific deliverables

Create or update these files:

- `docs/system/system_inventory.md`
- `docs/system/file_index.md`
- `docs/system/change_ledger.md`
- `docs/system/work_log.md`
- `docs/system/debug_map.md`
- `docs/system/incidents.md`
- `docs/system/observability_spec.md`

---

## Required report format

At the end of the task, output these sections:

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

## Quality bar

Do not give me vague statements like "improved reliability", "added better logging", or "cleaned up code".

**Be concrete.** Name files. Name functions. Name flows. Name error paths. Name missing instrumentation. Name exact fixes.

---

## Constraints

- No silent changes
- No fake completion
- No hidden assumptions
- No swallowed exceptions without context
- No critical path without logs
- No bug fix without root cause notes
- No code change without traceability
- No vague summary
- No skipping docs for important work

---

## Definition of success

Success means I can open the repo and answer:

- what changed
- why it changed
- where to debug
- how to reproduce failures
- how to inspect logs
- how to verify fixes
- what still needs work

Make the codebase act like a production system, not a prototype.

---

## Wrapper instructions for first run

Start by scanning the repository and creating the `docs/system/` baseline files before making feature or bug-fix changes. Then work in this order:

1. repository discovery
2. architecture map
3. observability gap analysis
4. baseline work log
5. implementation
6. validation
7. ledger and debug map update
8. final report

For every critical path, make sure logs answer:

- what operation started
- what input class was received
- what dependency was called
- what state changed
- what failed
- what error code applies
- what identifier can correlate the event
- what should be checked next
