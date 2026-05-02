# Receipts Quickstart — Go + slog + lumberjack

Tiny working demo. Proves the Receipts logger pattern actually writes structured logs to a rotated file.

**Requires Go 1.21+** (for `log/slog`).

## Run

```bash
go run main.go
```

Server listens on port `3002`. In another terminal:

```bash
# trigger logs
curl localhost:3002/hello
curl localhost:3002/error
curl -H 'x-correlation-id: my-test-id' localhost:3002/hello

# watch logs flow into the file
tail -f logs/app.log | jq
```

You'll see JSON lines like:

```json
{
  "time": "2026-05-02T17:30:00.123Z",
  "level": "INFO",
  "msg": "http.request",
  "service": "receipts-quickstart-go",
  "env": "local",
  "version": "0.0.1",
  "correlation_id": "my-test-id",
  "request_id": "9a4c2...",
  "operation": "http.request",
  "method": "GET",
  "path": "/hello",
  "status": "success",
  "status_code": 200,
  "duration_ms": 0
}
```

When the active log file hits 50MB, lumberjack rotates it (`logs/app-2026-05-02T...log`). It also rotates by age (max 30 days) and keeps 14 backups.

## What you're proving

- ✅ logs are **structured JSON**, not `fmt.Println`
- ✅ logs are written to **stdout AND** `logs/app.log` simultaneously
- ✅ **rotation** is wired (50MB cap, 14 backups, 30 days max age, gzip-compressed)
- ✅ **correlation IDs** flow from request header → log fields via `context.Context`
- ✅ **request lifecycle**: `started` → `success`/`failed` with `duration_ms`
- ✅ **error logs** carry `error_class` + `error_code`
- ✅ secrets (password / token / authorization / cookie / api_key) are redacted at the slog handler level
- ✅ graceful shutdown logs `app.shutdown` on SIGINT/SIGTERM

Stop the server, restart it, hit `/hello` again — you'll see the **same `logs/app.log`** being appended to. That's "saved logs."

## What's intentionally minimal

This demo is ~200 lines on purpose. Compared to the full cookbook ([`cookbooks/go-slog.md`](../../cookbooks/go-slog.md)):

- ✅ has: structured logger, lumberjack rotation, correlation context, request lifecycle, error codes, graceful shutdown
- ❌ skips: full `AppError` type with class hierarchy, `Instrument` generic wrapper, `CallDep` retry/timeout helper

Use the **cookbook** for production. Use this demo to see the loop work.

## Files

- [`main.go`](main.go) — entrypoint
- [`go.mod`](go.mod) — `github.com/google/uuid`, `gopkg.in/natefinch/lumberjack.v2`
- `.env.example` — config knobs
- `.gitignore` — `logs/`, `.env`
