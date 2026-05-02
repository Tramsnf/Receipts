"""Receipts quickstart — Python + FastAPI + structlog.

Proves structured JSON logs flow to BOTH stdout AND a rotated file.

Run:
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    python app.py

Then in another terminal:
    curl localhost:3001/hello
    curl localhost:3001/error
    curl localhost:3001/slow
    tail -f logs/app.log | jq

The current day's logs are in logs/app.log. After midnight UTC the file rotates
to logs/app.log.YYYY-MM-DD and a fresh logs/app.log starts.
"""
import asyncio
import logging
import os
import random
import time
import uuid
from contextlib import asynccontextmanager
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path

import structlog
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


# 1. Configure stdlib handlers (stdout + rotated file).
Path("logs").mkdir(exist_ok=True)

handlers: list[logging.Handler] = [logging.StreamHandler()]  # stdout

if os.environ.get("FILE_LOG", "1") != "0":
    fh = TimedRotatingFileHandler(
        "logs/app.log",
        when="midnight",
        interval=1,
        backupCount=14,    # keep 14 days
        utc=True,
    )
    fh.suffix = "%Y-%m-%d"
    handlers.append(fh)

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    handlers=handlers,
    format="%(message)s",   # structlog renders the JSON itself
    force=True,
)


# 2. Configure structlog for JSON output with contextvars merging.
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.JSONRenderer(),
    ],
    context_class=dict,
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

log = structlog.get_logger().bind(
    service=os.environ.get("SERVICE_NAME", "receipts-quickstart-py"),
    env=os.environ.get("APP_ENV", "local"),
    version=os.environ.get("APP_VERSION", "0.0.1"),
)


# 3. FastAPI app with correlation middleware + lifecycle logs.
@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("app.start", operation="app.start", status="success",
             port=int(os.environ.get("PORT", 3001)))
    yield
    log.info("app.shutdown", operation="app.shutdown", status="success")


app = FastAPI(lifespan=lifespan)


@app.middleware("http")
async def correlation_middleware(request: Request, call_next):
    correlation_id = request.headers.get("x-correlation-id") or str(uuid.uuid4())
    request_id = str(uuid.uuid4())
    structlog.contextvars.bind_contextvars(
        correlation_id=correlation_id,
        request_id=request_id,
    )
    start = time.time()
    log.info("http.request",
             operation="http.request",
             method=request.method, path=request.url.path,
             status="started")
    try:
        response = await call_next(request)
        log.info("http.request",
                 operation="http.request",
                 method=request.method, path=request.url.path,
                 status="success" if response.status_code < 400 else "failed",
                 status_code=response.status_code,
                 duration_ms=int((time.time() - start) * 1000))
        response.headers["x-correlation-id"] = correlation_id
        response.headers["x-request-id"] = request_id
        return response
    except Exception:
        log.exception("http.request",
                      operation="http.request",
                      status="failed",
                      duration_ms=int((time.time() - start) * 1000))
        raise
    finally:
        structlog.contextvars.clear_contextvars()


# 4. Routes
@app.get("/hello")
def hello():
    log.info("demo.hello", operation="demo.hello", step="greeting")
    return {"ok": True, "hello": "world"}


@app.get("/error")
def error():
    log.error("demo.error",
              operation="demo.error",
              error_class="business",
              error_code="E_BIZ_DEMO_ERROR",
              debug_context={"reason": "on-purpose for the demo"})
    return JSONResponse(
        status_code=422,
        content={"error_code": "E_BIZ_DEMO_ERROR", "message": "demo error"},
    )


@app.get("/slow")
async def slow():
    wait_ms = random.randint(100, 300)
    log.info("demo.slow", operation="demo.slow", status="started")
    await asyncio.sleep(wait_ms / 1000)
    log.info("demo.slow", operation="demo.slow", status="success", duration_ms=wait_ms)
    return {"ok": True, "waited_ms": wait_ms}


if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 3001)),
        log_config=None,   # don't let uvicorn override our logging config
    )
