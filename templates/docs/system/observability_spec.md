# Observability Spec

> The contract for logs, errors, metrics, and traces in this repository.
> Every code path must conform. Update when the contract changes.

---

## Log schema

Required fields on every important log:

| Field | Type | Notes |
|---|---|---|
| `timestamp` | ISO 8601 string | UTC |
| `level` | enum | `debug` \| `info` \| `warn` \| `error` \| `fatal` |
| `service` | string | service or app name |
| `env` | enum | `local` \| `dev` \| `staging` \| `prod` |
| `version` | string | semver or commit sha |
| `correlation_id` | string | trace across services |
| `request_id` \| `job_id` \| `trace_id` | string | scoped to operation |
| `module` | string | logical module |
| `function` | string | originating function or handler |
| `operation` | string | stable event name (e.g. `billing.charge.start`) |
| `status` | enum | `started` \| `success` \| `failed` |
| `duration_ms` | number | when applicable |
| `error_code` | string | when applicable, see taxonomy |
| `error_class` | string | when applicable |
| `message` | string | human-readable |
| `debug_context` | object | additional safe context |

### Event naming convention

`<domain>.<action>.<phase>` — e.g. `auth.login.start`, `auth.login.success`, `auth.login.failed`, `billing.charge.dependency.timeout`.

Use stable names. Adding a new field is fine. Renaming an existing event breaks dashboards.

---

## Correlation strategy

<!-- How correlation_id is generated, propagated, and attached to outbound calls -->

- **Generation**: <middleware / library>
- **HTTP propagation header**: `X-Correlation-Id` (or `traceparent` for W3C)
- **Inbound queue propagation**: <how it's read off message metadata>
- **Outbound HTTP**: <how it's set on outbound requests>
- **Outbound queue / event**: <how it's attached to message metadata>
- **Logger binding**: <how the logger is bound to the active correlation context>

---

## Severity rules

| Level | When to use |
|---|---|
| `debug` | local development, verbose tracing — must be off in prod by default |
| `info` | operation start / success, important state transitions |
| `warn` | recoverable failure, retry triggered, degraded path taken |
| `error` | unrecoverable failure for this operation, needs investigation |
| `fatal` | process must restart, data integrity at risk |

---

## Redaction rules

**Always redacted**:

- passwords, secrets, API keys, tokens
- raw `Authorization` headers, raw cookies
- credit card numbers, full SSN
- regulated PII (per applicable regs: GDPR, HIPAA, etc.)

**Truncated / hashed**:

- email addresses → hash or domain-only when not needed
- IP addresses → /24 or hashed when not needed for audit

**Never logged in full**:

- request / response bodies for auth, billing, or PII endpoints
- file contents for user uploads

---

## Error taxonomy

| Class | Code prefix | Examples | Operator meaning |
|---|---|---|---|
| validation | `E_VAL_*` | `E_VAL_REQUIRED_FIELD` | bad input from caller |
| auth / authz | `E_AUTH_*` | `E_AUTH_TOKEN_EXPIRED` | identity / permission issue |
| business rule | `E_BIZ_*` | `E_BIZ_INSUFFICIENT_FUNDS` | request rejected by business logic |
| dependency | `E_DEP_*` | `E_DEP_STRIPE_TIMEOUT` | upstream service failed |
| timeout | `E_TMO_*` | `E_TMO_DB_QUERY` | operation exceeded time budget |
| database | `E_DB_*` | `E_DB_CONSTRAINT_VIOLATION` | persistence layer issue |
| network | `E_NET_*` | `E_NET_DNS_FAILURE` | network-level failure |
| concurrency | `E_CONC_*` | `E_CONC_LOCK_CONFLICT` | race / lock / version conflict |
| internal | `E_INT_*` | `E_INT_INVARIANT_BROKEN` | bug — should never happen |

Each error class needs a stable code, a clear log shape, a consistent response strategy, and a clear operator meaning.

---

## Metrics plan

| Metric | Type | Labels | Purpose |
|---|---|---|---|
| `http_requests_total` | counter | `route`, `method`, `status` | request volume |
| `http_request_duration_seconds` | histogram | `route`, `method` | latency |
| `dependency_calls_total` | counter | `dep`, `op`, `outcome` | dep health |
| `job_runs_total` | counter | `job`, `outcome` | worker health |
| `errors_total` | counter | `error_class`, `error_code` | error rate |

**Cardinality rules**: do not use unbounded values (user_id, request_id) as label values.

---

## Tracing plan

- **Span boundaries**: every HTTP handler, every outbound dep call, every job run, every db transaction.
- **Standard attributes**: `service.name`, `service.version`, `operation`, `error_code` on failed spans.
- **Propagation format**: W3C Trace Context (`traceparent` / `tracestate`).
- **Sampling**: <strategy — head / tail, rate>

---

## Alert candidates

| Alert | Trigger | Severity |
|---|---|---|
| `error_rate_5m` | `errors_total / requests_total > 1%` for 5m | page |
| `latency_p99_5m` | p99 > <threshold> for 5m | page |
| `dependency_failure_rate` | dep failure rate > 5% for 5m | page |
| `dlq_depth` | DLQ size > 0 | ticket |
| `worker_stalled` | no job runs for <expected interval> | ticket |

---

## Dashboards to create

- [ ] Service overview (req rate, error rate, p50/p95/p99 latency)
- [ ] Dependency health (per-dep success rate, latency, retry rate)
- [ ] Worker / queue health (depth, throughput, age, DLQ)
- [ ] Auth health (login success / failure rate, suspicious failure spikes)
- [ ] Error taxonomy view (top error codes, trends)
