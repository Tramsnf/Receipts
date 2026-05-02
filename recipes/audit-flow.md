# Recipe: Audit Flow

Deep audit of a single user-facing flow (login, checkout, charge, signup, password-reset, …). Build a complete `debug_map.md` entry for that flow.

## Goal

Move from "we have a flow somewhere" to "we have a documented map of every entrypoint, every dependency, every log, every failure point, repro steps, and verification commands" for one named flow.

## Steps

1. **Identify the entrypoint(s)** — route, event handler, CLI command, cron, webhook receiver. There may be more than one (HTTP + queue consumer for the same flow).
2. **Walk control flow** layer by layer:
   - controller / handler
   - middleware
   - service layer
   - repository / data layer
   - external integrations (one per dep)
   - background jobs spawned (if any)
3. **Inventory logs** — for each layer, list the log events emitted (`auth.login.start`, `auth.login.dep.idp.call`, etc.). Flag silent stretches.
4. **Inventory failure boundaries** — every `try`/`catch`, every `error`/`exception`, every retry/timeout/circuit-breaker. Confirm each emits a structured error log with `error_class`, `error_code`, `correlation_id`.
5. **Build a reproduction script** — `curl` + payload, fixture file, queue producer, etc. Should reproduce both the happy path and at least one common failure.
6. **List likely failure points** — dependency timeout, validation failure, state conflict, auth denial, rate limit. For each, name the log event you'd grep to confirm it.
7. **Add the flow to `docs/system/debug_map.md`** using the template in `templates/docs/system/debug_map.md`.
8. **Open a `change_ledger.md` entry** if any logs were added during the audit.
9. **Open `incidents.md` entries** for any pre-existing bugs surfaced.

## Parallel strategy (Claude Code)

Spawn one subagent per layer (controller, service, repo, dep, jobs) using `Explore` for read-only walks. Each returns its layer's:

- file list
- log events emitted (event name + line)
- failure boundaries (line + classification)
- gaps

Main agent merges into the flow doc. Total wall time ≈ wall time of the slowest layer, not the sum.

## Single-agent fallback

Walk layers sequentially in the order above. Use parallel `Read` tool calls within a layer where possible.

## Output

- A new flow section in `docs/system/debug_map.md` with:
  - entrypoint(s)
  - dependent modules
  - external dependencies
  - state touched
  - logs emitted (event names + locations)
  - correlation ID source
  - likely failure points
  - reproduction steps
  - fix locations
  - verification commands
  - linked ledger / incident entries
- Optional: ledger entries for added logs
- Optional: incident entries for bugs found

## Definition of done

- A new engineer can debug a failure in this flow using only the `debug_map.md` entry.
- Every layer has at least one named log event.
- Every failure boundary has a confirmed `error_code`.
- The repro script runs locally and exercises the happy path.
