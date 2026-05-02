# Agent-Specific Installers

Drop-in files for the most common AI coding agents. Pick yours, copy the file into the right place, you're done.

| Agent | File | Where it goes |
|---|---|---|
| Cursor | [`cursor/.cursorrules`](cursor/.cursorrules) | repo root |
| Windsurf | [`windsurf/.windsurfrules`](windsurf/.windsurfrules) | repo root |
| Cline | [`cline/custom-instructions.md`](cline/custom-instructions.md) | paste into Cline → Settings → Custom Instructions |
| Roo Code | [`roo-code/system-prompt.md`](roo-code/system-prompt.md) | paste into a custom mode's system prompt |
| OpenHands | [`openhands/microagents/receipts.md`](openhands/microagents/receipts.md) | `.openhands/microagents/receipts.md` in repo root |
| Claude Code | the package itself | `~/.claude/skills/receipts/` or `.claude/skills/receipts/` |

All installers are condensed versions of [`SKILL.md`](../SKILL.md). The full prompt set with role + user prompts lives in [`prompts/`](../prompts/). The doc templates live in [`templates/docs/system/`](../templates/docs/system/).

## After installation

The agent will scaffold `docs/system/` baseline files on its first task in a repo. Templates are copied from `templates/docs/system/`.

## Validate

After dropping the file in, prompt the agent with:

> "Run a Receipts protocol scan on this repo and produce the baseline docs/system/ files."

If the agent does not generate `docs/system/system_inventory.md`, `change_ledger.md`, `debug_map.md`, etc., the rules file isn't loading. Check the agent's docs for the exact rules file location.
