// Receipts quickstart — Node + pino + pino-roll
// Proves structured JSON logs flow to BOTH stdout AND a rotated file.
//
// Run:
//   npm install
//   npm start
//
// Then in another terminal:
//   curl localhost:3000/hello
//   tail -f logs/app-$(date -u +%Y-%m-%d).log | jq

import express from 'express';
import pino from 'pino';
import { randomUUID } from 'node:crypto';
import { mkdirSync } from 'node:fs';

mkdirSync('logs', { recursive: true });

// Dual transport: stdout (12-factor) AND a rotated daily file.
// In prod, replace the pino-roll target with a transport that ships to
// your aggregator (Datadog / CloudWatch / Loki / Elasticsearch / Splunk).
const transport = pino.transport({
  targets: [
    {
      target: 'pino/file',
      level: 'info',
      options: { destination: 1 }, // stdout
    },
    {
      target: 'pino-roll',
      level: 'info',
      options: {
        file: 'logs/app',
        frequency: 'daily',
        dateFormat: 'yyyy-MM-dd',
        size: '50m',
        mkdir: true,
        extension: '.log',
        limit: { count: 14 }, // keep 14 days
      },
    },
  ],
});

const logger = pino(
  {
    level: process.env.LOG_LEVEL ?? 'info',
    base: {
      service: process.env.SERVICE_NAME ?? 'receipts-quickstart',
      env: process.env.APP_ENV ?? 'local',
      version: process.env.APP_VERSION ?? '0.0.1',
    },
    timestamp: pino.stdTimeFunctions.isoTime,
    redact: {
      paths: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token'],
      censor: '[REDACTED]',
    },
  },
  transport,
);

const app = express();
app.use(express.json());

// Correlation + request lifecycle middleware.
app.use((req, res, next) => {
  const correlation_id = req.header('x-correlation-id') || randomUUID();
  const request_id = randomUUID();
  req.log = logger.child({ correlation_id, request_id });

  res.setHeader('x-correlation-id', correlation_id);
  res.setHeader('x-request-id', request_id);

  const start = Date.now();
  req.log.info(
    { operation: 'http.request', method: req.method, path: req.path, status: 'started' },
    'http.request start',
  );

  res.on('finish', () => {
    const status = res.statusCode < 400 ? 'success' : 'failed';
    req.log.info(
      {
        operation: 'http.request',
        method: req.method,
        path: req.path,
        status,
        status_code: res.statusCode,
        duration_ms: Date.now() - start,
      },
      'http.request end',
    );
  });

  next();
});

// Routes
app.get('/hello', (req, res) => {
  req.log.info({ operation: 'demo.hello', step: 'greeting' }, 'saying hello');
  res.json({ ok: true, hello: 'world' });
});

app.get('/error', (req, res) => {
  req.log.error(
    {
      operation: 'demo.error',
      error_class: 'business',
      error_code: 'E_BIZ_DEMO_ERROR',
      debug_context: { reason: 'on-purpose for the demo' },
    },
    'demo error',
  );
  res.status(422).json({ error_code: 'E_BIZ_DEMO_ERROR', message: 'demo error' });
});

app.get('/slow', async (req, res) => {
  req.log.info({ operation: 'demo.slow', status: 'started' }, 'slow op begin');
  const wait = Math.floor(Math.random() * 200) + 100;
  await new Promise((r) => setTimeout(r, wait));
  req.log.info(
    { operation: 'demo.slow', status: 'success', duration_ms: wait },
    'slow op done',
  );
  res.json({ ok: true, waited_ms: wait });
});

// Startup log
const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  logger.info(
    { operation: 'app.start', status: 'success', port },
    `receipts-quickstart listening on :${port}`,
  );
});

// Graceful shutdown logging
function shutdown(signal) {
  logger.info(
    { operation: 'app.shutdown', status: 'started', signal },
    `received ${signal}, shutting down`,
  );
  setTimeout(() => process.exit(0), 50);
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
