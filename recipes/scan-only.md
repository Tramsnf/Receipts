# Recipe: Scan Only

Inventory + observability classification with **zero code changes**.

## Goal

Produce a current-state report of the repo's observability posture so the user can decide whether to invest in remediation, and where to start.

## Steps

1. **Run helper scripts in parallel** (background bash):
   - `python3 scripts/scan-observability.py --md . > docs/system/_scan_<date>.md`
   - `scripts/redaction-lint.sh . > docs/system/_redaction_<date>.md`
   - `scripts/find-error-boundaries.sh . > docs/system/_boundaries_<date>.md`
   - `scripts/log-coverage.sh . > docs/system/_log_coverage_<date>.md`
2. **Verify the heuristic** — sample 5–10 files per classification bucket. Confirm the heuristic call by reading the actual code. Promote/demote files as needed.
3. **Walk critical flows** — identify routes, jobs, workers, dep calls. For each, follow control flow and confirm logs at start / checkpoints / success / failure.
4. **Synthesize a summary**:
   - counts per classification (fully / partial / minimal / none)
   - top 10 highest-risk gaps (lowest score × highest blast radius)
   - flows with the worst log coverage
   - likely secret-leak hotspots (from redaction lint)
   - recommended next recipe + scope estimate
5. **Append a `work_log.md` entry** — record what was scanned, what was sampled, what was concluded. Do **NOT** modify any production code.

## Parallel strategy (Claude Code)

- Phase 1 (scripts): run all four scripts concurrently via background bash — no dependencies between them.
- Phase 2 (verification sampling): spawn one `Explore` subagent per classification bucket (max 4 concurrent). Each agent verifies its sample and returns its calls.
- Phase 3 (flow walk): spawn one `Explore` subagent per critical flow (max 4 concurrent).
- Phase 4 (synthesis): main agent merges into the summary.

## Single-agent fallback

- Background-launch all four scripts.
- While they run, the agent samples files using parallel `Read` tool calls.
- After scripts return, agent walks flows serially.
- Synthesis at the end.

## Output

- `docs/system/_scan_<date>.md`
- `docs/system/_redaction_<date>.md`
- `docs/system/_boundaries_<date>.md`
- `docs/system/_log_coverage_<date>.md`
- A summary report printed to the user
- One `work_log.md` entry recording the scan

## Definition of done

- All four script outputs are saved under `docs/system/`
- The user can answer: how observable is this repo right now?
- The user has a prioritized starter list for `remediate-all`
- **No production code was modified**
