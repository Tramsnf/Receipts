# Recipe: Bootstrap

First-touch initialization. Run when Receipts is freshly installed in a repo and `docs/system/` does not yet exist.

## Goal

Scaffold `docs/system/` baseline files, detect the stack, run the heuristic scan, and produce a one-page repo inventory the agent can build on.

## Steps

1. **Scaffold templates** — run `scripts/bootstrap.sh <repo-root>`. Skips files that already exist.
2. **Detect stack** — read manifests in parallel:
   - `package.json`, `pnpm-workspace.yaml`, `lerna.json` (Node)
   - `pyproject.toml`, `requirements.txt`, `Pipfile` (Python)
   - `go.mod` (Go)
   - `Cargo.toml` (Rust)
   - `pom.xml`, `build.gradle*` (JVM)
   - `Gemfile` (Ruby)
   - `.csproj`, `*.sln` (C#)
3. **Detect entrypoints** — common files:
   - Node: `src/index.*`, `src/server.*`, `src/main.*`, `bin/*`, `package.json#main`
   - Python: `__main__.py`, `manage.py`, `app.py`, `main.py`, `pyproject.toml#scripts`
   - Go: `cmd/*/main.go`, `main.go`
   - container: `Dockerfile`, `docker-compose.yml`
4. **Heuristic observability scan** — `python3 scripts/scan-observability.py --md <repo-root> > docs/system/_scan_baseline.md`
5. **Pre-fill `system_inventory.md`** with detected stack, entrypoints, dependencies, environments (read `.env.example`, `config/*`, `*.config.*`).
6. **Pre-fill `file_index.md`** with the worst offenders from the scan plus any files matching critical-path patterns (handlers, routes, middleware, jobs, workers, migrations).
7. **Decide log sinks** — fill in the "Log sinks & retention" table in `observability_spec.md`. If the user hasn't decided, propose the safe defaults:
   - local: stdout + rotated file under `./logs/app.log` (daily, 50MB, keep 14)
   - prod: stdout (12-factor) → orchestrator → aggregator (ask the user which one or detect from infra files: `ecs-task-definition.json`, `serverless.yml`, k8s manifests, Datadog agent configs)
   Add `logs/` to `.gitignore` if writing files locally.
8. **Append a bootstrap entry** to `change_ledger.md` and `work_log.md`.
9. **Report** — print:
   - stack detected
   - file count + classification breakdown
   - top 10 highest-risk files
   - log sinks chosen per env
   - recommended next recipe (`scan-only` for review, `remediate-all` to fix, `audit-flow <name>` to focus)

## Parallel strategy (Claude Code)

Phase 2 (stack detection) and Phase 4 (heuristic scan) run concurrently — neither modifies state.

Phase 5 and 6 (inventory + file_index pre-fill) can run in parallel: spawn two `general-purpose` subagents — one for `system_inventory.md`, one for `file_index.md` — both reading the scan output and manifests. Main agent merges and writes ledger entries.

## Single-agent fallback

Run steps 1 → 2 → 4 → 5 → 6 → 7 → 8 in order. Use background bash for the scan in step 4 while the agent reads manifests in parallel tool calls.

## Output

- `docs/system/system_inventory.md` (filled with detected info)
- `docs/system/file_index.md` (top critical files from scan)
- `docs/system/_scan_baseline.md` (heuristic scan)
- `docs/system/change_ledger.md` and `docs/system/work_log.md` (bootstrap entries appended)
- A short summary printed to the user

## Definition of done

- All seven `docs/system/` files exist
- `system_inventory.md` has at least: stack, entrypoints, top-3 dependencies, environments
- `file_index.md` has at least the 20 worst-offender files from the scan
- The user can answer "what is this repo?" by reading `system_inventory.md` alone
