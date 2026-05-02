# Receipts Quickstart — Node + pino

Tiny working demo. Proves the Receipts logger pattern actually writes structured logs to a rotated file.

## Run

```bash
npm install
npm start
```

Server listens on port `3000`. In another terminal:

```bash
# trigger logs
curl localhost:3000/hello
curl localhost:3000/error
curl -H 'x-correlation-id: my-test-id' localhost:3000/hello

# watch logs flow into the file
tail -f logs/app.$(date -u +%Y-%m-%d).*.log | jq
```

You'll see JSON lines like:

```json
{
  "level": "info",
  "time": "2026-05-02T06:30:00.123Z",
  "service": "receipts-quickstart",
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
  "msg": "http.request end"
}
```

And error lines like:

```json
{
  "level": "error",
  "operation": "demo.error",
  "error_class": "business",
  "error_code": "E_BIZ_DEMO_ERROR",
  "msg": "demo error"
}
```

## What you're proving

- ✅ logs are **structured JSON**, not `console.log`
- ✅ logs are written to **stdout AND** `logs/app.YYYY-MM-DD.N.log` (N is the rotation index within the day)
- ✅ **daily rotation** is wired (50MB cap, keep 14 backups)
- ✅ **correlation IDs** flow from request header → log fields
- ✅ **request lifecycle**: `started` → `success`/`failed` with `duration_ms`
- ✅ **error logs** carry `error_class` + `error_code`

Stop the server, restart it, hit `/hello` again — you'll see the **same log file** being appended to (until midnight UTC, when it rotates). That's "saved logs."

## What's intentionally minimal

This demo is ~70 lines on purpose. Compared to the full cookbook ([`cookbooks/node-pino.md`](../../cookbooks/node-pino.md)):

- ✅ has: structured logger, file rotation, correlation IDs, request lifecycle, error codes
- ❌ skips: AsyncLocalStorage propagation, full error class hierarchy, dep call wrapper, retry/timeout instrumentation, background job lifecycle

Use the **cookbook** for production. Use this demo to see the loop work.

## Files

- [`app.js`](app.js) — entrypoint
- [`package.json`](package.json) — `pino`, `pino-roll`, `express`
- `.env.example` — config knobs
- `.gitignore` — `node_modules/`, `logs/`, `.env`
