---
name: receipts
type: repo
agent: CodeActAgent
triggers: []
---

# Receipts Protocol

You operate under the Receipts protocol whenever you work on this repository.

**Treat missing logging, missing debug context, and missing error handling as production bugs, not nice-to-haves.**

## Before any code change

- Scan the relevant codebase area
- Build a system map: modules, request flow, state, integrations, error paths
- Classify each relevant file's observability: fully | partially | minimally | not observable
- Report gaps before implementing

## Required artifacts (create on first run, maintain after)

- `docs/system/system_inventory.md`
- `docs/system/file_index.md`
- `docs/system/change_ledger.md` (append-only)
- `docs/system/work_log.md`
- `docs/system/debug_map.md`
- `docs/system/incidents.md`
- `docs/system/observability_spec.md`

## Instrumentation contract

Every meaningful execution path must log:

- start of operation
- key checkpoints (state changes, dep calls, branches, retries)
- success with `duration_ms`
- failure with: operation, module, correlation_id, safe IDs, error_class, error_code, sanitized context, likely failing boundary, remediation hint

Required fields: `timestamp, level, service, env, version, correlation_id, request_id|job_id|trace_id, module, function, operation, status, duration_ms, error_code, error_class, message, debug_context`.

Redact secrets, tokens, passwords, raw auth headers, regulated PII.

## Error handling contract

No silent failures. No swallowed exceptions. No empty catch. No vague generic returns. No print-only debugging. No hidden fallbacks. No retry without retry logs. No async work without lifecycle logs. No state mutation without audit trail.

Error classes: validation `E_VAL_*`, auth `E_AUTH_*`, business `E_BIZ_*`, dependency `E_DEP_*`, timeout `E_TMO_*`, db `E_DB_*`, network `E_NET_*`, concurrency `E_CONC_*`, internal `E_INT_*`.

## Per-layer expectations

- Routes/handlers: request start, metadata, outcome, failures, latency
- Services: op start, decisions, external calls, state changes, failures
- Data layer: query ops, retry/timeout, not-found vs failure
- Jobs/workers: enqueue, dequeue, start, checkpoints, retries, backoff, DLQ, completion, duration
- External integrations: target dep, op, response class, timeout, retry, circuit-break, failure reason
- Auth: flow start, decision, denied access, token transitions, suspicious failures (never log secrets)

## Task lifecycle

1. Discovery
2. Map
3. Gap analysis
4. Plan
5. Baseline
6. Implement
7. Validate
8. Document
9. Report

## Definition of done

A task is done only when: code inspected, changes in `change_ledger.md`, logs adequate, docs updated, validation performed (or pending status explicit and explained), user can answer what changed / what broke / why / what's next.

## Final report sections

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
11. Files still missing logs or error handling
12. Files upgraded to production-grade observability
13. Error classes added or standardized
14. Correlation and trace propagation status

## Hard bans

- try/catch that hides errors
- catch-and-continue with no log
- returning null/false on failure with no explanation
- console-only observability
- generic "something failed" messages
- logging raw secrets
- implicit fallback with no trace
- async work with no lifecycle visibility
- state mutation with no audit trail
- untracked feature/bug-fix changes

Source: [github.com/Tramsnf/Receipts](https://github.com/Tramsnf/Receipts)
