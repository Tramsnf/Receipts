# Recipes

Named workflows the agent can run on demand. Each recipe is a self-contained operating contract: goal, steps, parallel strategy (where applicable), output, and when to use it.

| Recipe | When |
|---|---|
| [`bootstrap.md`](bootstrap.md) | First-time setup in a new repo |
| [`scan-only.md`](scan-only.md) | Read-only observability assessment, no code changes |
| [`remediate-all.md`](remediate-all.md) | Bulk upgrade everything below `fully observable` |
| [`audit-flow.md`](audit-flow.md) | Deep audit of one user-facing flow (login, checkout, charge, etc.) |
| [`incident-investigation.md`](incident-investigation.md) | Bug report → root cause → fix → prevention |

## Invocation

The user can ask for a recipe by name:

> "Run the Receipts remediate-all recipe."

> "Audit the charge flow."

> "Investigate the incident in #incident-channel — symptoms in the message."

The agent loads the recipe, follows the steps, and reports per the recipe's contract.

## Parallel orchestration

Recipes that benefit from parallelism (`remediate-all`, `audit-flow`, `incident-investigation`) describe their fan-out plan explicitly. On Claude Code with the `Agent` tool, the orchestrating agent spawns subagents per the plan. On other agents, the same recipe runs serially with maximum within-response parallelism (batched tool calls, background scripts).
