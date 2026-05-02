# Recipe: Incident Investigation

Take a bug report and produce a complete incident entry: symptom → trigger → root cause → fix → prevention.

## Goal

Move from "something broke" to a closed-loop incident record so the same class of bug can't repeat invisibly.

## Inputs

The user provides at minimum:

- a symptom description (user-visible or alert text)
- ideally a `correlation_id`, `request_id`, or timestamp
- ideally a sample failed request / error log

## Steps

1. **Capture the symptom** — user-visible AND internal (alert, log, metric). Both go in the incident entry.
2. **Search logs** — by `correlation_id` if known, otherwise by `error_code` + time window + module. Build a timeline of events for the failed operation.
3. **Identify the failing operation** — exact module, function, error class, error code. Cross-reference against `debug_map.md` for the flow.
4. **Walk the recent change ledger** — was anything modified in the affected module in the last N hours? Likely regression source.
5. **Reproduce locally** — write a repro test if one doesn't exist. The test should fail before the fix and pass after.
6. **Identify root cause** — *not* the trigger. The trigger is "a request came in"; the root cause is "the dependency wrapper had no timeout, so a slow Stripe call exhausted the connection pool."
7. **Implement the fix** — minimal but complete. Add structured logs that would have caught this earlier.
8. **Add prevention** — at least one of:
   - new test (the repro test)
   - new alert (e.g. `dlq_size > 0`)
   - new guardrail (circuit breaker, validation, type narrowing)
   - new doc entry in `debug_map.md`
9. **Write the incident entry** in `docs/system/incidents.md` using the template.
10. **Append the change_ledger.md entry** that links to the incident entry.

## Parallel strategy (Claude Code)

Useful concurrency points:

- **Phase A** (read-only, parallel):
  - Subagent 1 — search logs for the correlation_id and build the timeline
  - Subagent 2 — read recent `change_ledger.md` entries for the affected module
  - Subagent 3 — read `debug_map.md` for the flow to understand expected log shape
- **Phase B** (write, serial): root-cause analysis and fix happen in the main agent — this is where coherent reasoning matters most. Don't fan out.
- **Phase C** (verify + write, parallel):
  - Subagent — run the repro test and the regression suite
  - Main agent — write incident + ledger entries while the test runs

## Single-agent fallback

Walk steps in order. Use parallel tool calls within Phase A. Phases B and C stay serial.

## Output

- One new entry in `docs/system/incidents.md` with: status, detection time, source, impacted area, symptoms, root cause, trigger, fix, prevention, linked ledger + PR + commits, timeline.
- One new entry in `docs/system/change_ledger.md` for the fix.
- A repro test added to the test suite.
- Optionally: a `debug_map.md` update if the flow's failure profile changed.

## Definition of done

- A future engineer hitting the same symptom can find this incident entry by searching `error_code` or symptom text.
- The repro test fails on the pre-fix commit and passes on the fix commit.
- Prevention is concrete (a test, an alert, a guardrail, or a doc entry — not "be more careful").
- The incident entry distinguishes root cause from trigger explicitly.
