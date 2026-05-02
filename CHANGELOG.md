# Changelog

All notable changes to Receipts are tracked here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
