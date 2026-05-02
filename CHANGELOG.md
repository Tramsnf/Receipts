# Changelog

All notable changes to Receipts are tracked here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0] — 2026-05-02

### Added

- **Recipes** (`recipes/`) — named multi-step workflows with explicit parallel strategies:
  - `recipes/bootstrap.md` — first-touch repo setup; auto-runs when `docs/system/` is missing
  - `recipes/scan-only.md` — read-only observability assessment (no code changes)
  - `recipes/remediate-all.md` — bulk upgrade everything below `fully observable`, with parallel multi-agent fan-out on Claude Code
  - `recipes/audit-flow.md` — deep audit of one user-facing flow; builds the `debug_map.md` entry
  - `recipes/incident-investigation.md` — bug → root cause → fix → prevention loop
- **Helper scripts** (`scripts/`) — deterministic, fast helpers the agent runs before reasoning:
  - `scripts/bootstrap.sh` — scaffolds `docs/system/` from templates
  - `scripts/scan-observability.py` — heuristic per-file classifier with markdown or JSON output
  - `scripts/redaction-lint.sh` — flags log lines that may leak secrets
  - `scripts/find-error-boundaries.sh` — locates try/catch and likely swallowed exceptions
  - `scripts/log-coverage.sh` — per-file log-call density metric
- **Parallel orchestration directives** in `SKILL.md` — Claude Code multi-agent fan-out plan (Explore → synthesize → general-purpose impl → general-purpose verify → merge) with concurrency-safety rules.
- **Single-agent fallback directives** for Cursor / Cline / Windsurf / Roo Code / OpenHands — within-response parallelism, background scripts, batch checkpoints.
- **Auto-bootstrap directive** — agent runs the bootstrap recipe automatically on first encounter with a repo that has no `docs/system/`.
- **Capability matrix** in `README.md` — what works on each agent runtime.
- **FAQ section** in `README.md` — addresses "does this auto-fix existing code?", bug discovery limits, token cost.

### Changed

- `SKILL.md` now references recipes and scripts; describes parallel and single-agent execution modes explicitly.
- `README.md` directory tree includes `recipes/` and `scripts/`.
- `README.md` install section unchanged — recipes work transparently on every supported agent.

### Notes

Auto-bootstrap is read-mostly (only writes templates and one ledger entry). It's a prerequisite for all other recipes, so the skill runs it without asking permission. Override by passing `--no-bootstrap` to any recipe, or by pre-creating `docs/system/`.

---

## [0.2.1] — 2026-05-02

### Added

- Hero image (`assets/og-card.png`) embedded at the top of `README.md` for the repo landing page.
- `What it works with` section in `README.md` with explicit agent, language, framework, and use-case keywords for search discoverability.
- `Topics` and `Search` keyword block at the bottom of `README.md` for SEO.

### Removed

- `marketing/` directory removed from the repo. Launch tweet thread, Show HN draft, Reddit drafts, and the launch checklist are personal/local-only by design — they live outside the published package.

### Changed

- `README.md` directory tree no longer references `marketing/`.
- `.gitignore` now includes `marketing/` as a safety net so launch drafts don't get re-added accidentally.

---

## [0.2.0] — 2026-05-02

### Added

- **Drop-in installers** for major AI coding agents under `installers/`:
  - `installers/cursor/.cursorrules`
  - `installers/windsurf/.windsurfrules`
  - `installers/cline/custom-instructions.md`
  - `installers/roo-code/system-prompt.md`
  - `installers/openhands/microagents/receipts.md`
  - `installers/INSTALL.md` index
- **Language cookbooks** under `cookbooks/` with concrete patterns for logger setup, correlation context, error classes with stable codes, operation instrumentation, dependency call wrappers, and background job lifecycle:
  - `cookbooks/node-pino.md` — Node + pino + Express/Fastify + AsyncLocalStorage
  - `cookbooks/python-structlog.md` — Python + structlog + FastAPI + Celery
  - `cookbooks/go-slog.md` — Go 1.21+ `log/slog` + context propagation + generics
- **Launch materials** under `marketing/`:
  - `marketing/launch-tweet-thread.md` — 8-tweet thread + standalone hook variants
  - `marketing/launch-posts.md` — Show HN + r/LocalLLaMA + r/ChatGPTCoding + r/programming + r/devops drafts
  - `marketing/launch-checklist.md` — pre-launch, day-of, week-one checklist
- **Social preview assets** under `assets/`:
  - `assets/og-card.png` — 1280×640, drop-in for GitHub repo social preview
  - `assets/og-card.svg` — vector source
  - `assets/og-card.html` — browser-renderable version with system fonts

### Changed

- `LICENSE` copyright attributed to **trams (@Tramsnf)**.
- `skill.json` `author` field expanded to structured object with `name`, `github`, and `url`.
- `README.md` install section updated to point to per-agent drop-in files instead of generic instructions.
- `README.md` directory tree updated to include the new `installers/`, `cookbooks/`, `marketing/`, and `assets/` directories.

---

## [0.1.0] — 2026-05-02

### Added

- Initial release of the Receipts skill.
- `SKILL.md` — agent operating contract: mode detection (remediation vs greenfield), required artifacts, operating order, instrumentation policy, error handling policy, per-layer expectations, bans, file classification, definition of done, final report format.
- `skill.json` — portable manifest with agent compatibility list.
- `prompts/system.md` — full system prompt (Production Codebase Audit, Traceability, and Observability Enforcer).
- `prompts/role.md` — role definition (Principal Reliability Engineer + Codebase Historian).
- `prompts/user.md` — task framing template.
- `templates/docs/system/system_inventory.md` — architecture and dependency baseline.
- `templates/docs/system/file_index.md` — file ownership and blast-radius index.
- `templates/docs/system/change_ledger.md` — append-only change log template.
- `templates/docs/system/work_log.md` — chronological agent action log template.
- `templates/docs/system/debug_map.md` — flow-to-failure-point map template.
- `templates/docs/system/incidents.md` — root cause and incident log template.
- `templates/docs/system/observability_spec.md` — log schema and error taxonomy template.
- MIT `LICENSE`.
- `README.md` — install and usage guide for Claude Code, Cursor, Cline, Windsurf, Roo Code, OpenHands, and generic LLM workflows.
