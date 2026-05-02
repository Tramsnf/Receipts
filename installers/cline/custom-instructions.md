# Cline Custom Instructions — Receipts Protocol

> Paste this into **Cline → Settings → Custom Instructions** (or the equivalent slot in your VS Code Cline extension settings). Keep it scoped to the workspace if you want it project-only.

---

You operate under the **Receipts protocol** for this workspace.

**Treat missing logging, missing debug context, and missing error handling as production bugs, not nice-to-haves.**

## Before any code change

1. Scan the relevant codebase area — entrypoints, services, data layer, configs, tests, deployment, current logging.
2. Build a system map: modules, request flow, state boundaries, integrations, error paths.
3. Classify every relevant file's observability: **fully | partially | minimally | not observable**.
4. Identify and report gaps before implementing.

## Required artifacts to create or maintain in this repo

- `docs/system/system_inventory.md` — architecture, deps, entrypoints
- `docs/system/file_index.md` — purpose, owner, blast radius per file
- `docs/system/change_ledger.md` — append-only log of every change
- `docs/system/work_log.md` — chronological agent action log
- `docs/system/debug_map.md` — flow → entrypoints → logs → failure points → repro
- `docs/system/incidents.md` — bug → root cause → fix → prevention
- `docs/system/observability_spec.md` — log schema + error taxonomy + correlation strategy

If `templates/docs/system/` exists in the repo (e.g. from the Receipts package), copy those templates as the starting point.

## Instrumentation contract

Every meaningful execution path must log:

- **Start** of the operation
- **Key checkpoints** (state changes, dependency calls, branching, retries)
- **Success** with `duration_ms`
- **Failure** with: operation, module, correlation_id, safe identifiers, error_class, error_code, sanitized context, likely failing boundary, remediation hint

Required log fields: `timestamp, level, service, env, version, correlation_id, request_id|job_id|trace_id, module, function, operation, status, duration_ms, error_code, error_class, message, debug_context`.

Redact secrets, tokens, passwords, raw auth headers, regulated PII.

## Error handling contract

- **No** silent failures
- **No** swallowed exceptions or empty catch blocks
- **No** vague generic returns (null/false on failure with no log)
- **No** print-only debugging
- **No** hidden fallback behavior without logs
- **No** retry logic without retry logs
- **No** async work without lifecycle logs
- **No** state mutation without audit trail

Classify each error into a class with a stable code prefix:

- validation `E_VAL_*`
- auth `E_AUTH_*`
- business `E_BIZ_*`
- dependency `E_DEP_*`
- timeout `E_TMO_*`
- database `E_DB_*`
- network `E_NET_*`
- concurrency `E_CONC_*`
- internal `E_INT_*`

## Per-layer expectations

| Layer | Must log |
|---|---|
| Routes / handlers | request start, metadata, outcome, failures, latency |
| Services | op start, decisions, external calls, state changes, failures |
| Data layer | query/persist ops, retry/timeout, not-found vs failure distinction |
| Jobs / workers | enqueue, dequeue, start, checkpoints, retries, backoff, DLQ, completion, duration |
| External integrations | target dep, op, response class, timeout, retry, circuit-break, failure reason |
| Auth flows | flow start, decision, denied access, token transitions, suspicious failures (never log secrets) |

## Task lifecycle

1. Discovery — scan repo
2. Map — model modules, flow, state, integrations
3. Gap analysis — classify files, identify missing logs/error boundaries
4. Plan — scope, risk, additions needed, rollback
5. Baseline — capture current behavior, test status, blind spots
6. Implement — minimal but complete; add structured logs and error boundaries
7. Validate — tests, type checks, lint, build, manual repro
8. Document — update ledger, work log, debug map, incidents, observability spec
9. Report — what changed, what's risky, what's next

## Definition of done

A task is only done when:

- relevant code was inspected
- changes are traceable in `change_ledger.md`
- logs/observability were added or confirmed adequate
- docs were updated
- validation was performed (or pending status is explicit and explained)
- the user can answer: what changed, what broke, why, what to do next

Do not claim success unless verified. If something can't be verified, state exactly what remains unverified and why.

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
11. Files still missing logs or error handling
12. Files upgraded to production-grade observability
13. Error classes added or standardized
14. Correlation and trace propagation status
