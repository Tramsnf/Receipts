# Examples

Runnable demos that prove the Receipts logger pattern works end-to-end. Clone the repo, `cd` into one, follow the README, and watch structured JSON land in both stdout and a rotated file.

| Demo | Stack | Run |
|---|---|---|
| [`quickstart-node`](quickstart-node/) | Node + Express + pino + pino-roll | `npm install && npm start` |

PRs welcome for `quickstart-python` (FastAPI + structlog) and `quickstart-go` (net/http + slog + lumberjack).

## What the demos show

- structured JSON logs (no `console.log`)
- written to **stdout AND** `logs/app-YYYY-MM-DD.log` simultaneously
- daily rotation with size + age caps (per the cookbook defaults)
- correlation IDs propagated through the request lifecycle
- request lifecycle logs (`started` → `success`/`failed` with `duration_ms`)
- error logs with stable `error_code` + `error_class`

These are *minimal* — the cookbooks (`cookbooks/`) carry the full production-grade pattern (AsyncLocalStorage propagation, full error hierarchy, dep call wrappers, background job lifecycle). Use the cookbook for production; use the demos to see the basic loop working in 30 seconds.
