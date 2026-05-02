# Cookbook: Node.js + pino

Drop-in patterns that satisfy the Receipts instrumentation contract for a TypeScript/JavaScript service using [`pino`](https://getpino.io).

## 1. Logger setup

```ts
// src/observability/logger.ts
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  base: {
    service: process.env.SERVICE_NAME,
    env: process.env.NODE_ENV,
    version: process.env.APP_VERSION ?? process.env.GIT_SHA,
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'req.headers["x-api-key"]',
      '*.password',
      '*.token',
      '*.apiKey',
      '*.secret',
      'body.password',
      'body.token',
    ],
    censor: '[REDACTED]',
  },
});
```

## 2. Correlation context (AsyncLocalStorage)

```ts
// src/observability/correlation.ts
import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import { logger } from './logger';

type Ctx = { correlation_id: string; request_id?: string; job_id?: string };
const store = new AsyncLocalStorage<Ctx>();

export function withCorrelation<T>(
  fn: () => T,
  ids: Partial<Ctx> = {},
): T {
  return store.run(
    {
      correlation_id: ids.correlation_id ?? randomUUID(),
      request_id: ids.request_id,
      job_id: ids.job_id,
    },
    fn,
  );
}

export const log = () => logger.child(store.getStore() ?? {});
```

## 3. Express / Fastify middleware

```ts
// src/observability/middleware.ts
import { randomUUID } from 'node:crypto';
import type { Request, Response, NextFunction } from 'express';
import { withCorrelation, log } from './correlation';

export function correlationMiddleware(req: Request, res: Response, next: NextFunction) {
  const correlation_id = (req.header('x-correlation-id') as string) || randomUUID();
  const request_id = randomUUID();

  res.setHeader('x-correlation-id', correlation_id);
  res.setHeader('x-request-id', request_id);

  withCorrelation(() => {
    const start = Date.now();
    log().info(
      {
        operation: 'http.request',
        method: req.method,
        path: req.path,
        status: 'started',
      },
      'http request started',
    );

    res.on('finish', () => {
      log().info(
        {
          operation: 'http.request',
          method: req.method,
          path: req.path,
          status: res.statusCode < 400 ? 'success' : 'failed',
          status_code: res.statusCode,
          duration_ms: Date.now() - start,
        },
        'http request completed',
      );
    });

    next();
  }, { correlation_id, request_id });
}
```

## 4. Error classes with stable codes

```ts
// src/errors/AppError.ts
export type ErrorClass =
  | 'validation' | 'auth' | 'business' | 'dependency'
  | 'timeout' | 'database' | 'network' | 'concurrency' | 'internal';

export class AppError extends Error {
  constructor(
    public readonly code: string,           // e.g. 'E_DEP_STRIPE_TIMEOUT'
    message: string,
    public readonly errorClass: ErrorClass,
    public readonly httpStatus: number = 500,
    public readonly context: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// concrete subclasses for ergonomics
export const ValidationError = (code: string, msg: string, ctx = {}) =>
  new AppError(code, msg, 'validation', 400, ctx);
export const AuthError = (code: string, msg: string, ctx = {}) =>
  new AppError(code, msg, 'auth', 401, ctx);
export const BusinessError = (code: string, msg: string, ctx = {}) =>
  new AppError(code, msg, 'business', 422, ctx);
export const DependencyError = (code: string, msg: string, ctx = {}) =>
  new AppError(code, msg, 'dependency', 502, ctx);
export const TimeoutError = (code: string, msg: string, ctx = {}) =>
  new AppError(code, msg, 'timeout', 504, ctx);
```

## 5. Operation instrumentation wrapper

```ts
// src/observability/instrument.ts
import { log } from './correlation';
import { AppError } from '../errors/AppError';

export async function instrument<T>(
  operation: string,
  module: string,
  fn: () => Promise<T>,
  context: Record<string, unknown> = {},
): Promise<T> {
  const start = Date.now();
  log().info({ operation, module, status: 'started', ...context }, `${operation} started`);

  try {
    const result = await fn();
    log().info(
      { operation, module, status: 'success', duration_ms: Date.now() - start, ...context },
      `${operation} success`,
    );
    return result;
  } catch (err) {
    const isApp = err instanceof AppError;
    log().error(
      {
        operation,
        module,
        status: 'failed',
        duration_ms: Date.now() - start,
        error_class: isApp ? err.errorClass : 'internal',
        error_code: isApp ? err.code : 'E_INT_UNEXPECTED',
        debug_context: isApp ? err.context : undefined,
        err,
        ...context,
      },
      `${operation} failed`,
    );
    throw err;
  }
}
```

## 6. Dependency call wrapper (with timeout + retry logging)

```ts
// src/observability/dep.ts
import { log } from './correlation';
import { DependencyError, TimeoutError } from '../errors/AppError';

export async function callDep<T>(
  dep: string,                     // e.g. 'stripe', 'sendgrid'
  operation: string,               // e.g. 'charge.create'
  fn: () => Promise<T>,
  opts: { timeoutMs?: number; retries?: number } = {},
): Promise<T> {
  const { timeoutMs = 5000, retries = 2 } = opts;
  let attempt = 0;

  while (true) {
    attempt++;
    const start = Date.now();
    log().info({ dep, operation, attempt, status: 'started' }, `${dep}.${operation} call`);

    try {
      const result = await Promise.race([
        fn(),
        new Promise<T>((_, reject) =>
          setTimeout(() => reject(new TimeoutError(`E_TMO_${dep.toUpperCase()}`, `${dep}.${operation} timeout`, { timeoutMs })), timeoutMs),
        ),
      ]);
      log().info(
        { dep, operation, attempt, status: 'success', duration_ms: Date.now() - start },
        `${dep}.${operation} success`,
      );
      return result;
    } catch (err) {
      const last = attempt > retries;
      log().warn(
        {
          dep,
          operation,
          attempt,
          status: last ? 'failed' : 'retry',
          duration_ms: Date.now() - start,
          err,
        },
        `${dep}.${operation} ${last ? 'failed' : 'retry'}`,
      );
      if (last) {
        throw new DependencyError(
          `E_DEP_${dep.toUpperCase()}`,
          `${dep}.${operation} failed after ${attempt} attempts`,
          { cause: err instanceof Error ? err.message : String(err) },
        );
      }
      await new Promise((r) => setTimeout(r, 100 * attempt)); // simple backoff
    }
  }
}
```

## 7. Putting it together — handler

```ts
// src/routes/charge.ts
import type { Request, Response } from 'express';
import { instrument } from '../observability/instrument';
import { callDep } from '../observability/dep';
import { ValidationError, AppError } from '../errors/AppError';

export async function chargeHandler(req: Request, res: Response) {
  try {
    const result = await instrument(
      'billing.charge',
      'billing-service',
      async () => {
        if (!req.body.amount) throw ValidationError('E_VAL_AMOUNT_REQUIRED', 'amount required');

        const stripe = await callDep('stripe', 'charge.create', () =>
          stripeClient.charges.create({ amount: req.body.amount, customer: req.body.customer_id }),
        );

        return { id: stripe.id };
      },
      { user_id: (req as any).user?.id, customer_id: req.body.customer_id },
    );

    res.json(result);
  } catch (err) {
    const isApp = err instanceof AppError;
    res.status(isApp ? err.httpStatus : 500).json({
      error_code: isApp ? err.code : 'E_INT_UNEXPECTED',
      message: isApp ? err.message : 'internal error',
    });
  }
}
```

## 8. Background job lifecycle

```ts
// src/jobs/processChargeJob.ts
import { withCorrelation } from '../observability/correlation';
import { instrument } from '../observability/instrument';

queue.process('charge.process', async (job) => {
  await withCorrelation(
    () => instrument('jobs.charge.process', 'billing-worker', async () => {
      // ... job work ...
    }, { job_id: job.id, attempt: job.attemptsMade + 1 }),
    { correlation_id: job.data.correlation_id, job_id: job.id },
  );
});
```

## 9. Log persistence — sinks beyond stdout

Stdout vanishes when the process exits. For local dev, dual-write to a rotated file. For staging/prod, ship stdout to an aggregator.

### Local dev: stdout + rotated file (pino-roll)

Install: `npm i pino pino-roll`

```ts
// src/observability/logger.ts
import pino from 'pino';

const transport = pino.transport({
  targets: [
    // 1. stdout (12-factor) — captured by your runtime in prod
    { target: 'pino/file', level: 'info', options: { destination: 1 } },
    // 2. local rotated file — useful in dev, off in prod (set FILE_LOG=0)
    ...(process.env.FILE_LOG !== '0'
      ? [{
          target: 'pino-roll',
          level: 'info',
          options: {
            file: 'logs/app',
            frequency: 'daily',
            size: '50m',
            mkdir: true,
            extension: '.log',
            limit: { count: 14 },  // keep 14 days
          },
        }]
      : []),
  ],
});

export const logger = pino({ /* base config from §1 */ }, transport);
```

Add `logs/` to `.gitignore`. View tail with `tail -f logs/app-$(date +%Y-%m-%d).log | jq`.

### Production: stdout + ship to aggregator

Pick one of the official transports:

| Aggregator | Transport |
|---|---|
| Datadog | `pino-datadog-transport` |
| CloudWatch | `pino-cloudwatch-transport` |
| Loki / Grafana Cloud | `pino-loki` |
| Elasticsearch / OpenSearch | `pino-elasticsearch` |
| Splunk | `pino-socket` to HEC |

```ts
// production transport (replace local-file target with the aggregator)
const transport = pino.transport({
  targets: [
    { target: 'pino/file', level: 'info', options: { destination: 1 } },  // stdout
    {
      target: 'pino-loki',
      level: 'info',
      options: {
        host: process.env.LOKI_URL,
        labels: { service: process.env.SERVICE_NAME, env: process.env.NODE_ENV },
      },
    },
  ],
});
```

Document the chosen transport in `docs/system/observability_spec.md` under "Log sinks & retention" — before this code ships.

## What this gives you

- Every HTTP request has a correlation_id propagated through the entire async tree
- Every operation logs `started` / `success` / `failed` with `duration_ms`
- Every dependency call logs attempt count, retries, and outcome
- Every error has a stable `error_code` and `error_class`
- Secrets are redacted at the logger level
- Background jobs inherit correlation IDs from their producers
- **Logs are durable** — local rotation keeps 14 days, prod ships to your aggregator
