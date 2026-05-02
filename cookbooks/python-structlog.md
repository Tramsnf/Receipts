# Cookbook: Python + structlog

Drop-in patterns that satisfy the Receipts instrumentation contract for a Python service using [`structlog`](https://www.structlog.org).

## 1. Logger setup

```python
# src/observability/logger.py
import os
import structlog
import logging

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.dict_tracebacks,
        _redact_secrets,
        structlog.processors.JSONRenderer(),
    ],
    context_class=dict,
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

log = structlog.get_logger().bind(
    service=os.environ.get("SERVICE_NAME"),
    env=os.environ.get("APP_ENV"),
    version=os.environ.get("APP_VERSION") or os.environ.get("GIT_SHA"),
)


_SECRET_KEYS = {"password", "token", "api_key", "apikey", "secret", "authorization", "cookie"}

def _redact_secrets(_, __, event_dict):
    def redact(obj):
        if isinstance(obj, dict):
            return {k: ("[REDACTED]" if k.lower() in _SECRET_KEYS else redact(v)) for k, v in obj.items()}
        if isinstance(obj, list):
            return [redact(v) for v in obj]
        return obj
    return redact(event_dict)
```

## 2. Correlation context

```python
# src/observability/correlation.py
import uuid
import structlog
from contextlib import contextmanager

@contextmanager
def correlation(correlation_id: str | None = None, request_id: str | None = None, job_id: str | None = None):
    structlog.contextvars.bind_contextvars(
        correlation_id=correlation_id or str(uuid.uuid4()),
        **({"request_id": request_id} if request_id else {}),
        **({"job_id": job_id} if job_id else {}),
    )
    try:
        yield
    finally:
        structlog.contextvars.unbind_contextvars("correlation_id", "request_id", "job_id")
```

## 3. FastAPI middleware

```python
# src/observability/middleware.py
import time
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from .correlation import correlation
from .logger import log

class CorrelationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        correlation_id = request.headers.get("x-correlation-id") or str(uuid.uuid4())
        request_id = str(uuid.uuid4())

        with correlation(correlation_id=correlation_id, request_id=request_id):
            start = time.time()
            log.info("http.request", operation="http.request", method=request.method,
                     path=request.url.path, status="started")
            try:
                response = await call_next(request)
            except Exception:
                log.exception("http.request",
                              operation="http.request", method=request.method,
                              path=request.url.path, status="failed",
                              duration_ms=int((time.time() - start) * 1000))
                raise
            log.info("http.request",
                     operation="http.request", method=request.method, path=request.url.path,
                     status="success" if response.status_code < 400 else "failed",
                     status_code=response.status_code,
                     duration_ms=int((time.time() - start) * 1000))
            response.headers["x-correlation-id"] = correlation_id
            response.headers["x-request-id"] = request_id
            return response
```

## 4. Error classes with stable codes

```python
# src/errors.py
from typing import Literal

ErrorClass = Literal[
    "validation", "auth", "business", "dependency",
    "timeout", "database", "network", "concurrency", "internal",
]

class AppError(Exception):
    def __init__(
        self,
        code: str,                   # e.g. "E_DEP_STRIPE_TIMEOUT"
        message: str,
        error_class: ErrorClass,
        http_status: int = 500,
        **context,
    ):
        super().__init__(message)
        self.code = code
        self.error_class = error_class
        self.http_status = http_status
        self.context = context


class ValidationError(AppError):
    def __init__(self, code, message, **ctx):
        super().__init__(code, message, "validation", 400, **ctx)

class AuthError(AppError):
    def __init__(self, code, message, **ctx):
        super().__init__(code, message, "auth", 401, **ctx)

class BusinessError(AppError):
    def __init__(self, code, message, **ctx):
        super().__init__(code, message, "business", 422, **ctx)

class DependencyError(AppError):
    def __init__(self, code, message, **ctx):
        super().__init__(code, message, "dependency", 502, **ctx)

class TimeoutErr(AppError):
    def __init__(self, code, message, **ctx):
        super().__init__(code, message, "timeout", 504, **ctx)
```

## 5. Operation instrumentation decorator

```python
# src/observability/instrument.py
import time
import functools
from typing import Callable, TypeVar, ParamSpec
from .logger import log
from ..errors import AppError

P = ParamSpec("P")
T = TypeVar("T")


def instrument(operation: str, module: str):
    def decorator(fn: Callable[P, T]) -> Callable[P, T]:
        @functools.wraps(fn)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
            start = time.time()
            log.info("op.start", operation=operation, module=module, status="started")
            try:
                result = fn(*args, **kwargs)
            except AppError as e:
                log.error("op.failed",
                          operation=operation, module=module, status="failed",
                          duration_ms=int((time.time() - start) * 1000),
                          error_class=e.error_class, error_code=e.code,
                          debug_context=e.context, exc_info=True)
                raise
            except Exception as e:
                log.error("op.failed",
                          operation=operation, module=module, status="failed",
                          duration_ms=int((time.time() - start) * 1000),
                          error_class="internal", error_code="E_INT_UNEXPECTED",
                          message=str(e), exc_info=True)
                raise
            log.info("op.success",
                     operation=operation, module=module, status="success",
                     duration_ms=int((time.time() - start) * 1000))
            return result
        return wrapper
    return decorator
```

## 6. Dependency call wrapper

```python
# src/observability/dep.py
import time
from typing import Callable, TypeVar
from .logger import log
from ..errors import DependencyError, TimeoutErr

T = TypeVar("T")

def call_dep(
    dep: str,                       # e.g. "stripe"
    operation: str,                 # e.g. "charge.create"
    fn: Callable[[], T],
    timeout_s: float = 5.0,
    retries: int = 2,
) -> T:
    attempt = 0
    last_exc: Exception | None = None
    while True:
        attempt += 1
        start = time.time()
        log.info("dep.call", dep=dep, operation=operation, attempt=attempt, status="started")
        try:
            # NOTE: timeout_s is illustrative — apply via your http client / asyncio.wait_for
            result = fn()
            log.info("dep.call",
                     dep=dep, operation=operation, attempt=attempt, status="success",
                     duration_ms=int((time.time() - start) * 1000))
            return result
        except Exception as e:
            last_exc = e
            last = attempt > retries
            log.warning("dep.call",
                        dep=dep, operation=operation, attempt=attempt,
                        status="failed" if last else "retry",
                        duration_ms=int((time.time() - start) * 1000),
                        cause=str(e))
            if last:
                raise DependencyError(
                    f"E_DEP_{dep.upper()}",
                    f"{dep}.{operation} failed after {attempt} attempts",
                    cause=str(e),
                ) from e
            time.sleep(0.1 * attempt)
```

## 7. Putting it together

```python
# src/routes/charge.py
from fastapi import APIRouter, HTTPException
from ..observability.instrument import instrument
from ..observability.dep import call_dep
from ..errors import AppError, ValidationError

router = APIRouter()

@instrument("billing.charge", "billing-service")
def _charge(amount: int, customer_id: str) -> dict:
    if amount <= 0:
        raise ValidationError("E_VAL_AMOUNT_INVALID", "amount must be positive", amount=amount)
    stripe = call_dep("stripe", "charge.create", lambda: stripe_client.charges.create(
        amount=amount, customer=customer_id,
    ))
    return {"id": stripe.id}


@router.post("/charge")
def charge(payload: dict):
    try:
        return _charge(payload["amount"], payload["customer_id"])
    except AppError as e:
        raise HTTPException(status_code=e.http_status, detail={"error_code": e.code, "message": str(e)})
```

## 8. Background job lifecycle (Celery example)

```python
# src/jobs/process_charge.py
from celery import shared_task
from ..observability.correlation import correlation
from ..observability.instrument import instrument

@shared_task(bind=True)
def process_charge(self, payload: dict):
    correlation_id = payload.get("correlation_id")
    with correlation(correlation_id=correlation_id, job_id=self.request.id):
        @instrument("jobs.charge.process", "billing-worker")
        def _run():
            # ... job work ...
            pass
        _run()
```

## 9. Log persistence — sinks beyond stdout

Stdout vanishes when the process exits. Dual-write to a rotated file locally; ship stdout to an aggregator in prod.

### Local dev: stdout + rotated file

```python
# src/observability/sinks.py
import logging
import os
from logging.handlers import TimedRotatingFileHandler

def configure_handlers():
    os.makedirs("logs", exist_ok=True)

    handlers: list[logging.Handler] = [logging.StreamHandler()]  # stdout

    if os.environ.get("FILE_LOG", "1") != "0":
        file_handler = TimedRotatingFileHandler(
            "logs/app.log",
            when="midnight",
            interval=1,
            backupCount=14,        # keep 14 days
            encoding="utf-8",
            utc=True,
        )
        handlers.append(file_handler)

    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        handlers=handlers,
        format="%(message)s",      # structlog renders the JSON itself
        force=True,
    )
```

Call `configure_handlers()` once at startup before importing the structlog logger from §1. Add `logs/` to `.gitignore`. Tail with `tail -f logs/app.log | jq`.

### Production: stdout + ship to aggregator

| Aggregator | Library |
|---|---|
| Datadog | `ddtrace.contrib.logging` (auto-correlates traces) |
| CloudWatch | `watchtower` |
| Loki / Grafana Cloud | `python-logging-loki` |
| Elasticsearch | `python-ecs-logging` + Filebeat or `cmreslogs` |
| Splunk | `splunk_handler` |

```python
# add the aggregator handler in production only
import os, logging

def configure_handlers():
    handlers: list[logging.Handler] = [logging.StreamHandler()]  # stdout always

    if os.environ.get("APP_ENV") == "prod":
        import logging_loki
        loki = logging_loki.LokiHandler(
            url=os.environ["LOKI_URL"],
            tags={"service": os.environ.get("SERVICE_NAME"), "env": "prod"},
            version="1",
        )
        handlers.append(loki)

    logging.basicConfig(level="INFO", handlers=handlers, format="%(message)s", force=True)
```

Document the chosen aggregator in `docs/system/observability_spec.md` under "Log sinks & retention" before this code ships.

## What this gives you

- Every request and job has a correlation_id propagated via `contextvars`
- Every operation logs `started` / `success` / `failed` with `duration_ms`
- Every dependency call logs attempts, retries, and final outcome
- Every error has a stable `error_code` and `error_class`
- Secrets are redacted at the structlog processor level
- Stacktraces captured via `dict_tracebacks` for safe JSON output
