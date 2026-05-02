# Examples

Runnable demos that prove the Receipts logger pattern works end-to-end. Clone the repo, `cd` into one, follow the README, and watch structured JSON land in both stdout and a rotated file.

| Demo | Stack | Port | Run |
|---|---|---|---|
| [`quickstart-node`](quickstart-node/) | Express + pino + pino-roll | 3000 | `npm install && npm start` |
| [`quickstart-python`](quickstart-python/) | FastAPI + structlog + TimedRotatingFileHandler | 3001 | `python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && python app.py` |
| [`quickstart-go`](quickstart-go/) | net/http + log/slog + lumberjack | 3002 | `go run main.go` (Go 1.21+) |

All three were verified locally — each writes structured JSON logs to a rotated file under `logs/` while also emitting to stdout.

## What the demos show

- structured JSON logs (no `console.log`)
- written to **stdout AND** `logs/app-YYYY-MM-DD.log` simultaneously
- daily rotation with size + age caps (per the cookbook defaults)
- correlation IDs propagated through the request lifecycle
- request lifecycle logs (`started` → `success`/`failed` with `duration_ms`)
- error logs with stable `error_code` + `error_class`

These are *minimal* — the cookbooks (`cookbooks/`) carry the full production-grade pattern (AsyncLocalStorage propagation, full error hierarchy, dep call wrappers, background job lifecycle). Use the cookbook for production; use the demos to see the basic loop working in 30 seconds.
