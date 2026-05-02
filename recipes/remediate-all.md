# Recipe: Remediate All

Bulk-upgrade every file from "less than fully observable" up to fully observable, in parallel where possible.

## Goal

Move the repo from its current observability posture to a state where every meaningful execution path has structured logs, error boundaries, correlation IDs, and stable error codes — without breaking tests.

## Pre-flight

- `docs/system/` must exist. If not, run `bootstrap` first.
- `git status` must be clean. Commit or stash uncommitted work first.
- `npm test`/`pytest`/`go test` (or whatever the repo uses) must pass on `main`. Don't start from broken.

## Strategy

### Phase 1 — Scan (parallel)

**Goal:** know every file's current state.

- Spawn one `Explore` subagent per top-level directory (`src/`, `lib/`, `app/`, `internal/`, etc.). Cap at 6 concurrent.
- Each subagent reads its files, runs the heuristic scan output for its slice, and returns:
  - classifications (verified, not just heuristic)
  - per-file gap list (missing logs, swallowed exceptions, missing error classes, missing correlation propagation)
- Save scan to `docs/system/_scan_<date>.md`.

### Phase 2 — Plan (main agent)

**Goal:** a partitioned, deterministic remediation queue.

- Merge subagent classifications into a unified queue.
- Score each file: `risk = blast_radius × (4 - score) / 4` where blast_radius is read from `file_index.md` when present.
- Sort descending.
- Partition into batches of ≤8 files each, ensuring no two batches modify the same file.
- Estimate concurrency based on context budget. Default to 4 concurrent implementation agents.

### Phase 3 — Implement (parallel)

**Goal:** upgrade every batch.

- Spawn N `general-purpose` subagents (one per batch).
- Each subagent receives:
  - its batch (file list)
  - the cookbook for the language(s) involved (`cookbooks/node-pino.md`, `python-structlog.md`, `go-slog.md`, etc.)
  - the observability spec (`docs/system/observability_spec.md`)
- Each subagent must:
  - read every file in its batch
  - add structured logs at start / key checkpoints / success / failure
  - introduce or reuse error classes with stable codes (`E_VAL_*`, `E_DEP_*`, etc.)
  - propagate correlation IDs through the call chain
  - redact secrets at the logger level
  - run tests for its slice (`npm test path/to/batch` or equivalent)
  - stage a per-agent ledger entry in `docs/system/_ledger_staging_<batch-id>.md`
- Stream per-batch progress to the user.

### Phase 4 — Verify (parallel)

**Goal:** no regressions.

- Spawn one `general-purpose` QA subagent per implementation batch.
- Each QA agent runs:
  - `git diff` for its batch
  - the test suite for the affected paths
  - the type checker (if applicable)
  - the linter
- Each returns: `pass` | `fail` with diff details. On fail, the impl batch is rolled back via `git restore`.

### Phase 5 — Synthesize (main agent)

**Goal:** unified history.

- Merge per-batch ledger entries into `docs/system/change_ledger.md` (newest at top).
- Update `docs/system/file_index.md` with new classifications.
- Update `docs/system/debug_map.md` for any flow whose log shape changed.
- Open one `docs/system/incidents.md` entry for any pre-existing bug surfaced during remediation.
- Print final report (see "Output" below).

## Concurrency safety

- Partition file ownership before spawning. Verify no overlap.
- Subagent ledger writes go to per-agent staging files; main agent merges atomically.
- Run `git status` between phases. If unexpected changes appear, halt.
- On any test failure in Phase 4, stop launching new batches; report what's done, what's pending.

## Streaming

- Announce phase transitions (`Phase 1: scanning…`, `Phase 3: implementing batch 2 of 6…`).
- After each batch finishes, print a one-line summary (files changed, logs added, tests passed).
- Do not silence progress — the user should see remediation happen, not wait for a wall of text at the end.

## Single-agent fallback

Without subagent support:

- Run Phase 1 via parallel `Read` and background `scan-observability.py` calls.
- Run Phase 3 sequentially, batch by batch, with the same in-batch rules.
- Verify after each batch (Phase 4 inline). On failure, roll back that batch and continue with the next.
- Slower but fully equivalent.

## Output

Final report sections (printed to the user):

1. Repository scan summary (before / after)
2. Files upgraded (count + paths)
3. Files unchanged (count + reason)
4. Files rolled back (count + reason)
5. Logs added or improved (count + samples)
6. Error classes added or standardized
7. Correlation propagation status
8. Tests passed / failed
9. Bugs found in flight (linked `incidents.md` entries)
10. Remaining risks (files still below `fully observable` and why they were skipped)
11. Recommended next recipe

## Definition of done

- Every file targeted by the remediation queue is now classified `fully` or has a documented reason for staying `partial` (e.g., upstream lib limitation).
- Tests pass on `main`.
- `docs/system/change_ledger.md` has one merged entry covering the run.
- `docs/system/file_index.md` reflects the new state.
- The user can answer: what was upgraded, what was skipped (why), and what's still risky.
