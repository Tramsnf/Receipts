# Changelog

All notable changes to Receipts are tracked here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
