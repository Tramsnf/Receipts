#!/usr/bin/env bash
# Per-file log call density. Useful for spotting silent files in a critical path.
# Usage: log-coverage.sh [path]
set -euo pipefail

ROOT="${1:-.}"
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "# Log Coverage — $ts"
echo
echo "Per-file count of structured log calls and total non-blank lines, sorted by"
echo "lowest density first. Files at the top are silent; investigate whether they"
echo "belong on a critical path."
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

# Build the file list once.
files=$(grep -REl "" "${INCLUDES[@]}" "${EXCLUDES[@]}" "$ROOT" 2>/dev/null || true)

if [ -z "$files" ]; then
  echo "_No source files found under $ROOT._"
  exit 0
fi

printf "%-80s | %6s | %6s | %s\n" "File" "Lines" "Logs" "Logs/100"
printf "%-80s-+-%6s-+-%6s-+--------\n" "$(printf '%.0s-' {1..80})" "------" "------"

# For each file, count non-blank lines and structured log call sites.
echo "$files" | while IFS= read -r f; do
  [ -z "$f" ] && continue
  lines=$(awk 'NF{c++} END{print c+0}' "$f" 2>/dev/null || echo 0)
  logs=$(grep -cE "(logger|log|slog)\.(Info|Warn|Error|Debug|info|warn|error|debug)|fmt\.Println" "$f" 2>/dev/null || echo 0)
  if [ "$lines" -lt 10 ]; then continue; fi
  density=$(awk -v l="$logs" -v n="$lines" 'BEGIN{ if (n==0) print 0; else printf "%.1f", (l*100)/n }')
  printf "%-80s | %6d | %6d | %s\n" "$f" "$lines" "$logs" "$density"
done | sort -t'|' -k4 -n
