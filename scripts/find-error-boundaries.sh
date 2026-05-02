#!/usr/bin/env bash
# Locate try/catch and likely swallowed exceptions.
# Usage: find-error-boundaries.sh [path]
set -euo pipefail

ROOT="${1:-.}"
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "# Error Boundary Inventory — $ts"
echo
echo "Locates try/catch patterns. Use as a triage starting point — agent should"
echo "open each finding to confirm whether the catch is silent or logged."
echo

INCLUDES=(
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx"
  --include="*.mjs" --include="*.cjs" --include="*.py" --include="*.go"
  --include="*.rb" --include="*.java" --include="*.cs" --include="*.rs"
)
EXCLUDES=(
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist
  --exclude-dir=build --exclude-dir=__pycache__ --exclude-dir=vendor
  --exclude-dir=target --exclude-dir=coverage
)

echo "## Empty catch blocks (JS/TS — high confidence swallowed exception)"
echo
out=$(grep -REn "catch\s*\([^)]*\)\s*\{\s*\}" "${INCLUDES[@]}" "${EXCLUDES[@]}" "$ROOT" 2>/dev/null || true)
if [ -n "$out" ]; then
  echo '```'
  echo "$out"
  echo '```'
else
  echo "_(none detected)_"
fi
echo

echo "## Empty except blocks (Python — \`except: pass\`)"
echo
out=$(grep -REn -A1 "except\b[^:]*:" "${INCLUDES[@]}" "${EXCLUDES[@]}" "$ROOT" 2>/dev/null \
  | grep -B1 "^\s*pass\s*$" || true)
if [ -n "$out" ]; then
  echo '```'
  echo "$out"
  echo '```'
else
  echo "_(none detected)_"
fi
echo

echo "## All try/catch sites (manual review for log presence)"
echo
total=$(grep -REn "^\s*(try|except)\b|catch\s*\(" "${INCLUDES[@]}" "${EXCLUDES[@]}" "$ROOT" 2>/dev/null | wc -l | tr -d ' ')
echo "**Total try/except/catch sites:** $total"
echo
echo "Run \`grep -REn -A5 \"catch (\" $ROOT\` and verify each catch logs the error"
echo "with \`logger.error\`/\`log.exception\`/\`slog.Error\` (not console.log, not silent)."
