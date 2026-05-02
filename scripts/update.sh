#!/usr/bin/env bash
# Update an installed Receipts skill in place (git pull).
# Run from anywhere — the script resolves its own location.
#
# Behavior:
#   - if installed via `git clone`: fetch + ff-only pull, show diff summary
#   - if installed via copy/zip: print clone instructions and exit 1
#   - refuses to pull on uncommitted local changes
#   - reminds about installer files copied into other repos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "# Receipts update — $ts"
echo
echo "Skill location: \`$SKILL_DIR\`"

if ! git -C "$SKILL_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  cat <<EOF

This install is **NOT a git checkout** — likely a copy or zip extract.

## To update

Re-clone over the existing directory:

    rm -rf "$SKILL_DIR"
    git clone https://github.com/Tramsnf/Receipts.git "$SKILL_DIR"

Or download the latest release tarball:

    https://github.com/Tramsnf/Receipts/releases/latest

If you only copied installer files (.cursorrules, .windsurfrules,
custom-instructions.md, microagents/receipts.md) into individual repos,
re-copy them from the latest release.
EOF
  exit 1
fi

cd "$SKILL_DIR"

current_sha=$(git rev-parse --short HEAD)
current_subject=$(git log -1 --pretty=%s)
echo "Current: \`$current_sha\` — $current_subject"

if [ -n "$(git status --porcelain)" ]; then
  echo
  echo "**warn**: uncommitted local changes detected. Stash or commit before updating."
  echo
  git status --short
  exit 1
fi

echo
echo "Fetching from origin…"
if ! git fetch origin --tags --quiet 2>&1; then
  echo "**error**: \`git fetch\` failed. Check network and remote access." >&2
  exit 1
fi

local_sha=$(git rev-parse @)
remote_sha=$(git rev-parse '@{u}' 2>/dev/null || git rev-parse origin/main)

if [ "$local_sha" = "$remote_sha" ]; then
  echo
  echo "**Already up to date.**"
  latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "(none)")
  skill_version=$(grep -m1 '"version"' skill.json 2>/dev/null | sed 's/[^0-9.]//g' || echo "?")
  echo
  echo "skill.json version: \`$skill_version\`  ·  latest tag: \`$latest_tag\`"
  exit 0
fi

echo
echo "## Pending commits"
echo
echo '```'
git log --oneline "$local_sha..$remote_sha" | head -25
echo '```'
echo
echo "Pulling (ff-only)…"
git pull --ff-only origin main --quiet

new_sha=$(git rev-parse --short HEAD)
new_subject=$(git log -1 --pretty=%s)
echo
echo "## Updated"
echo
echo "Now at: \`$new_sha\` — $new_subject"

latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "(none)")
skill_version=$(grep -m1 '"version"' skill.json 2>/dev/null | sed 's/[^0-9.]//g' || echo "?")
echo
echo "skill.json version: \`$skill_version\`  ·  latest tag: \`$latest_tag\`"

echo
echo "## Reminder"
echo
echo "If you copied installer files (.cursorrules, .windsurfrules,"
echo "custom-instructions.md, microagents/receipts.md) into individual repos,"
echo "re-copy them from \`$SKILL_DIR/installers/\` to those repos to pick up changes."
