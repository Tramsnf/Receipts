#!/usr/bin/env bash
# Bootstrap docs/system/ from Receipts templates if missing.
# Usage: bootstrap.sh [target-repo-root]
set -euo pipefail

REPO_ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$SKILL_DIR/templates/docs/system"

if [ ! -d "$TEMPLATES" ]; then
  echo "error: templates not found at $TEMPLATES" >&2
  echo "is this script running from inside the Receipts skill package?" >&2
  exit 1
fi

if [ ! -d "$REPO_ROOT" ]; then
  echo "error: target repo root does not exist: $REPO_ROOT" >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/docs/system"

scaffolded=()
skipped=()

for tpl in "$TEMPLATES"/*.md; do
  name=$(basename "$tpl")
  target="$REPO_ROOT/docs/system/$name"
  if [ -f "$target" ]; then
    skipped+=("$name")
  else
    cp "$tpl" "$target"
    scaffolded+=("$name")
  fi
done

echo "# Bootstrap report"
echo ""
echo "**Repo:** \`$(cd "$REPO_ROOT" && pwd)\`"
echo "**Skill:** \`$SKILL_DIR\`"
echo ""
if [ ${#scaffolded[@]} -gt 0 ]; then
  echo "## Scaffolded (${#scaffolded[@]})"
  for f in "${scaffolded[@]}"; do
    echo "- \`docs/system/$f\`"
  done
  echo ""
fi
if [ ${#skipped[@]} -gt 0 ]; then
  echo "## Already existed — skipped (${#skipped[@]})"
  for f in "${skipped[@]}"; do
    echo "- \`docs/system/$f\`"
  done
  echo ""
fi

echo "## Next steps"
echo ""
echo "1. Have the agent fill \`docs/system/system_inventory.md\` with stack, entrypoints, dependencies."
echo "2. Run the scan: \`python3 $SKILL_DIR/scripts/scan-observability.py --md . > docs/system/_scan_baseline.md\`"
echo "3. Have the agent verify the heuristic classifications and fill \`docs/system/file_index.md\`."
echo "4. Append a bootstrap entry to \`docs/system/work_log.md\` and \`docs/system/change_ledger.md\`."
