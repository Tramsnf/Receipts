# Receipts Cookbooks

Concrete language-specific patterns that satisfy the Receipts instrumentation contract.

Each cookbook gives you:

- structured logger setup
- correlation ID propagation
- error class hierarchy with stable codes
- request / job boundary instrumentation
- dependency call wrapper with timeout + retry logging
- redaction of secrets

| Stack | File |
|---|---|
| Node + pino | [`node-pino.md`](node-pino.md) |
| Python + structlog | [`python-structlog.md`](python-structlog.md) |
| Go + slog | [`go-slog.md`](go-slog.md) |

Want one for your stack? Open an issue or PR. Useful additions: Ruby + ougai, Java + logback structured, Rust + tracing, .NET + Serilog, Elixir + Logger.
