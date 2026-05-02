# Receipts Quickstart — Python + FastAPI + structlog

Tiny working demo. Proves the Receipts logger pattern actually writes structured logs to a rotated file.

## Run

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Server listens on port `3001`. In another terminal:

```bash
# trigger logs
curl localhost:3001/hello
curl localhost:3001/error
curl -H 'x-correlation-id: my-test-id' localhost:3001/hello

# watch logs flow into the file
tail -f logs/app.log | jq
```

You'll see JSON lines like:

```json
{
  "service": "receipts-quickstart-py",
  "env": "local",
  "version": "0.0.1",
  "correlation_id": "my-test-id",
  "request_id": "9a4c2...",
  "operation": "http.request",
  "method": "GET",
  "path": "/hello",
  "status": "success",
  "status_code": 200,
  "duration_ms": 3,
  "event": "http.request",
  "level": "info",
  "timestamp": "2026-05-02T17:30:00.123456Z"
}
```

After midnight UTC the file rotates: today's stays as `logs/app.log`, yesterday's becomes `logs/app.log.YYYY-MM-DD`. Up to 14 days are kept.

## What you're proving

- ✅ logs are **structured JSON**, not `print()`
- ✅ logs are written to **stdout AND** `logs/app.log`
- ✅ **daily rotation** is wired (UTC midnight, keep 14 backups)
- ✅ **correlation IDs** flow from request header → log fields (via `structlog.contextvars`)
- ✅ **request lifecycle**: `started` → `success`/`failed` with `duration_ms`
- ✅ **error logs** carry `error_class` + `error_code`
- ✅ uvicorn doesn't fight your logging config (we pass `log_config=None`)

Stop the server, restart it, hit `/hello` again — you'll see the **same `logs/app.log`** being appended to. That's "saved logs."

## What's intentionally minimal

This demo is ~150 lines on purpose. Compared to the full cookbook ([`cookbooks/python-structlog.md`](../../cookbooks/python-structlog.md)):

- ✅ has: structured logger, file rotation, correlation IDs, request lifecycle, error codes
- ❌ skips: `@instrument` decorator, full error class hierarchy, dependency call wrapper with retries, Celery job lifecycle

Use the **cookbook** for production. Use this demo to see the loop work.

## Files

- [`app.py`](app.py) — entrypoint
- [`requirements.txt`](requirements.txt) — `fastapi`, `uvicorn`, `structlog`
- `.env.example` — config knobs
- `.gitignore` — `.venv/`, `logs/`, `__pycache__/`, `.env`
