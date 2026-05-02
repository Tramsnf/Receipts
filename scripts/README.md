# Helper Scripts

Deterministic, fast helpers for the agent to run before reasoning. They speed up scans and surface obvious gaps; they don't replace the agent's judgment.

| Script | Purpose | Runtime |
|---|---|---|
| [`scan-observability.py`](scan-observability.py) | Heuristic per-file classification (fully / partial / minimal / none) | Python 3.7+ |
| [`bootstrap.sh`](bootstrap.sh) | Scaffold `docs/system/` from templates | bash |
| [`redaction-lint.sh`](redaction-lint.sh) | Flag log lines that may leak secrets | bash + grep |
| [`find-error-boundaries.sh`](find-error-boundaries.sh) | Locate try/catch and likely swallowed exceptions | bash + grep |
| [`log-coverage.sh`](log-coverage.sh) | Per-file log-call density metric | bash + grep |

## Usage

All scripts are safe to run multiple times and exit non-zero only on hard failures.

```bash
# from your repo root, with the skill installed at ~/.claude/skills/receipts/

# 1. scaffold docs/system/
~/.claude/skills/receipts/scripts/bootstrap.sh .

# 2. classify observability across the repo
python3 ~/.claude/skills/receipts/scripts/scan-observability.py --md . > docs/system/_scan_baseline.md

# 3. flag potential secret leaks
~/.claude/skills/receipts/scripts/redaction-lint.sh . > docs/system/_redaction_lint.md

# 4. inventory error boundaries
~/.claude/skills/receipts/scripts/find-error-boundaries.sh . > docs/system/_error_boundaries.md

# 5. log density per file
~/.claude/skills/receipts/scripts/log-coverage.sh . > docs/system/_log_coverage.md
```

The agent can also call these in parallel via background bash, capture outputs, and merge into the baseline scan. See [`recipes/scan-only.md`](../recipes/scan-only.md) for the full pattern.
