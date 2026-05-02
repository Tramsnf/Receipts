#!/usr/bin/env bash
# Flag log lines that may leak secrets, tokens, passwords, or PII.
# Usage: redaction-lint.sh [path]
set -euo pipefail

ROOT="${1:-.}"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "# Redaction Lint — $ts"
echo
echo "Scans for log calls whose arguments include sensitive identifiers."
echo "Heuristic — false positives expected; agent should verify."
echo

# Patterns: any log/console call whose args contain a sensitive word.
# Uses fixed-string greps then filters. POSIX-ish for portability across mac/linux.

INCLUDES=(
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx"
  --include="*.mjs" --include="*.cjs" --include="*.py" --include="*.go"
  --include="*.rb" --include="*.java" --include="*.cs" --include="*.rs"
  --include="*.php" --include="*.kt"
)
EXCLUDES=(
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist
  --exclude-dir=build --exclude-dir=__pycache__ --exclude-dir=vendor
  --exclude-dir=target --exclude-dir=coverage
)

# Combined regex of risk words AND log/print calls in one line.
# We accept some imprecision and let the agent triage.
PATTERN='(log|logger|console|print|fmt\.Print)\.?\w*\([^)]*(password|passwd|secret|token|api[-_]?key|apikey|authorization|cookie|credit[-_]?card|ssn|social[-_]?security|priv(ate)?[-_]?key|access[-_]?token|refresh[-_]?token|client[-_]?secret|bearer)[^)]*\)'

found=0
matches=$(grep -REn "$PATTERN" "${INCLUDES[@]}" "${EXCLUDES[@]}" "$ROOT" 2>/dev/null || true)

if [ -z "$matches" ]; then
  echo "**Result:** no obvious leak patterns detected."
  echo
  echo "_This does not guarantee redaction is correct — sampling-based review still recommended._"
else
  count=$(echo "$matches" | wc -l | tr -d ' ')
  echo "**Result:** $count suspicious lines."
  echo
  echo "## Findings"
  echo
  echo '```'
  echo "$matches"
  echo '```'
  echo
  echo "## Recommended action"
  echo
  echo "For each line above, verify the value is redacted at the logger level"
  echo "(pino \`redact:\`, structlog processor, slog \`ReplaceAttr\`, etc.) before"
  echo "the field reaches the structured log sink. If not, redact at boundary."
fi
