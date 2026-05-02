# Cookbook: Go + slog

Drop-in patterns that satisfy the Receipts instrumentation contract for a Go service using [`log/slog`](https://pkg.go.dev/log/slog) (Go 1.21+).

## 1. Logger setup

```go
// internal/observability/logger.go
package observability

import (
	"log/slog"
	"os"
	"strings"
)

var secretKeys = map[string]struct{}{
	"password": {}, "token": {}, "api_key": {}, "apikey": {},
	"secret": {}, "authorization": {}, "cookie": {},
}

func init() {
	level := slog.LevelInfo
	switch strings.ToLower(os.Getenv("LOG_LEVEL")) {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	}

	h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:       level,
		ReplaceAttr: redact,
	})
	base := slog.New(h).With(
		"service", os.Getenv("SERVICE_NAME"),
		"env", os.Getenv("APP_ENV"),
		"version", firstNonEmpty(os.Getenv("APP_VERSION"), os.Getenv("GIT_SHA")),
	)
	slog.SetDefault(base)
}

func redact(_ []string, a slog.Attr) slog.Attr {
	if _, ok := secretKeys[strings.ToLower(a.Key)]; ok {
		return slog.String(a.Key, "[REDACTED]")
	}
	return a
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}
```

## 2. Correlation context

```go
// internal/observability/correlation.go
package observability

import (
	"context"
	"log/slog"

	"github.com/google/uuid"
)

type ctxKey string

const (
	correlationKey ctxKey = "correlation_id"
	requestKey     ctxKey = "request_id"
	jobKey         ctxKey = "job_id"
)

type IDs struct {
	CorrelationID string
	RequestID     string
	JobID         string
}

func WithIDs(ctx context.Context, ids IDs) context.Context {
	if ids.CorrelationID == "" {
		ids.CorrelationID = uuid.NewString()
	}
	ctx = context.WithValue(ctx, correlationKey, ids.CorrelationID)
	if ids.RequestID != "" {
		ctx = context.WithValue(ctx, requestKey, ids.RequestID)
	}
	if ids.JobID != "" {
		ctx = context.WithValue(ctx, jobKey, ids.JobID)
	}
	return ctx
}

func Logger(ctx context.Context) *slog.Logger {
	l := slog.Default()
	if v := ctx.Value(correlationKey); v != nil {
		l = l.With("correlation_id", v)
	}
	if v := ctx.Value(requestKey); v != nil {
		l = l.With("request_id", v)
	}
	if v := ctx.Value(jobKey); v != nil {
		l = l.With("job_id", v)
	}
	return l
}
```

## 3. HTTP middleware

```go
// internal/observability/middleware.go
package observability

import (
	"net/http"
	"time"

	"github.com/google/uuid"
)

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (sr *statusRecorder) WriteHeader(code int) {
	sr.status = code
	sr.ResponseWriter.WriteHeader(code)
}

func CorrelationMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		correlationID := r.Header.Get("X-Correlation-Id")
		if correlationID == "" {
			correlationID = uuid.NewString()
		}
		requestID := uuid.NewString()

		w.Header().Set("X-Correlation-Id", correlationID)
		w.Header().Set("X-Request-Id", requestID)

		ctx := WithIDs(r.Context(), IDs{CorrelationID: correlationID, RequestID: requestID})
		log := Logger(ctx)

		start := time.Now()
		log.InfoContext(ctx, "http.request",
			"operation", "http.request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", "started",
		)

		sr := &statusRecorder{ResponseWriter: w, status: 200}
		next.ServeHTTP(sr, r.WithContext(ctx))

		status := "success"
		if sr.status >= 400 {
			status = "failed"
		}
		log.InfoContext(ctx, "http.request",
			"operation", "http.request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", status,
			"status_code", sr.status,
			"duration_ms", time.Since(start).Milliseconds(),
		)
	})
}
```

## 4. Error type with stable codes

```go
// internal/errors/apperror.go
package errors

import "fmt"

type ErrorClass string

const (
	ClassValidation  ErrorClass = "validation"
	ClassAuth        ErrorClass = "auth"
	ClassBusiness    ErrorClass = "business"
	ClassDependency  ErrorClass = "dependency"
	ClassTimeout     ErrorClass = "timeout"
	ClassDatabase    ErrorClass = "database"
	ClassNetwork     ErrorClass = "network"
	ClassConcurrency ErrorClass = "concurrency"
	ClassInternal    ErrorClass = "internal"
)

type AppError struct {
	Code       string                 // e.g. "E_DEP_STRIPE_TIMEOUT"
	Message    string
	Class      ErrorClass
	HTTPStatus int
	Context    map[string]any
	Cause      error
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error { return e.Cause }

func Validation(code, msg string, ctx map[string]any) *AppError {
	return &AppError{Code: code, Message: msg, Class: ClassValidation, HTTPStatus: 400, Context: ctx}
}
func Dependency(code, msg string, cause error, ctx map[string]any) *AppError {
	return &AppError{Code: code, Message: msg, Class: ClassDependency, HTTPStatus: 502, Context: ctx, Cause: cause}
}
func Timeout(code, msg string, ctx map[string]any) *AppError {
	return &AppError{Code: code, Message: msg, Class: ClassTimeout, HTTPStatus: 504, Context: ctx}
}
```

## 5. Operation instrumentation

```go
// internal/observability/instrument.go
package observability

import (
	"context"
	"errors"
	"time"

	apperr "github.com/you/yourapp/internal/errors"
)

func Instrument[T any](ctx context.Context, operation, module string, fn func(context.Context) (T, error)) (T, error) {
	var zero T
	start := time.Now()
	log := Logger(ctx).With("operation", operation, "module", module)
	log.InfoContext(ctx, "op.start", "status", "started")

	result, err := fn(ctx)
	dur := time.Since(start).Milliseconds()

	if err != nil {
		var ae *apperr.AppError
		if errors.As(err, &ae) {
			log.ErrorContext(ctx, "op.failed",
				"status", "failed",
				"duration_ms", dur,
				"error_class", string(ae.Class),
				"error_code", ae.Code,
				"debug_context", ae.Context,
				"err", err.Error(),
			)
		} else {
			log.ErrorContext(ctx, "op.failed",
				"status", "failed",
				"duration_ms", dur,
				"error_class", "internal",
				"error_code", "E_INT_UNEXPECTED",
				"err", err.Error(),
			)
		}
		return zero, err
	}

	log.InfoContext(ctx, "op.success", "status", "success", "duration_ms", dur)
	return result, nil
}
```

## 6. Dependency call wrapper

```go
// internal/observability/dep.go
package observability

import (
	"context"
	"strings"
	"time"

	apperr "github.com/you/yourapp/internal/errors"
)

func CallDep[T any](
	ctx context.Context,
	dep, operation string,
	fn func(context.Context) (T, error),
	timeout time.Duration,
	retries int,
) (T, error) {
	var zero T
	for attempt := 1; ; attempt++ {
		start := time.Now()
		log := Logger(ctx).With("dep", dep, "operation", operation, "attempt", attempt)
		log.InfoContext(ctx, "dep.call", "status", "started")

		callCtx, cancel := context.WithTimeout(ctx, timeout)
		result, err := fn(callCtx)
		cancel()

		if err == nil {
			log.InfoContext(ctx, "dep.call",
				"status", "success",
				"duration_ms", time.Since(start).Milliseconds(),
			)
			return result, nil
		}

		last := attempt > retries
		status := "retry"
		if last {
			status = "failed"
		}
		log.WarnContext(ctx, "dep.call",
			"status", status,
			"duration_ms", time.Since(start).Milliseconds(),
			"cause", err.Error(),
		)
		if last {
			return zero, apperr.Dependency(
				"E_DEP_"+strings.ToUpper(dep),
				dep+"."+operation+" failed after "+itoa(attempt)+" attempts",
				err,
				map[string]any{"attempts": attempt},
			)
		}
		time.Sleep(time.Duration(attempt) * 100 * time.Millisecond)
	}
}

func itoa(n int) string {
	// tiny helper to avoid strconv import in this snippet
	return fmt.Sprintf("%d", n)
}
```

## 7. Putting it together — handler

```go
// internal/handlers/charge.go
package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	apperr "github.com/you/yourapp/internal/errors"
	obs "github.com/you/yourapp/internal/observability"
)

func ChargeHandler(stripeClient StripeClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			Amount     int64  `json:"amount"`
			CustomerID string `json:"customer_id"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)

		result, err := obs.Instrument(r.Context(), "billing.charge", "billing-service",
			func(ctx context.Context) (map[string]any, error) {
				if body.Amount <= 0 {
					return nil, apperr.Validation("E_VAL_AMOUNT_INVALID", "amount must be positive",
						map[string]any{"amount": body.Amount})
				}
				charge, err := obs.CallDep(ctx, "stripe", "charge.create",
					func(ctx context.Context) (StripeCharge, error) {
						return stripeClient.CreateCharge(ctx, body.Amount, body.CustomerID)
					}, 5*time.Second, 2)
				if err != nil {
					return nil, err
				}
				return map[string]any{"id": charge.ID}, nil
			})

		if err != nil {
			var ae *apperr.AppError
			if errors.As(err, &ae) {
				w.WriteHeader(ae.HTTPStatus)
				_ = json.NewEncoder(w).Encode(map[string]string{
					"error_code": ae.Code,
					"message":    ae.Message,
				})
				return
			}
			w.WriteHeader(http.StatusInternalServerError)
			_ = json.NewEncoder(w).Encode(map[string]string{"error_code": "E_INT_UNEXPECTED"})
			return
		}

		_ = json.NewEncoder(w).Encode(result)
	}
}
```

## What this gives you

- Correlation IDs propagated through `context.Context`
- Every operation logs `started` / `success` / `failed` with `duration_ms`
- Every dependency call logs attempt count, retries, and outcome
- Stable `error_code` + `error_class` on every failure
- Secret keys redacted at the slog handler level
- HTTP middleware sets correlation headers on response for downstream services
