// Receipts quickstart — Go + log/slog + lumberjack.
//
// Proves structured JSON logs flow to BOTH stdout AND a rotated file.
//
// Requires Go 1.21+ for log/slog.
//
// Run:
//
//	go run main.go
//
// Then in another terminal:
//
//	curl localhost:3002/hello
//	curl localhost:3002/error
//	curl localhost:3002/slow
//	tail -f logs/app.log | jq
package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"gopkg.in/natefinch/lumberjack.v2"
)

// 1. Logger setup with file rotation.

var logger *slog.Logger

type ctxKey string

const (
	correlationKey ctxKey = "correlation_id"
	requestKey     ctxKey = "request_id"
)

var secretKeys = map[string]struct{}{
	"password": {}, "token": {}, "authorization": {}, "cookie": {}, "api_key": {},
}

func redact(_ []string, a slog.Attr) slog.Attr {
	if _, ok := secretKeys[strings.ToLower(a.Key)]; ok {
		return slog.String(a.Key, "[REDACTED]")
	}
	return a
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func init() {
	_ = os.MkdirAll("logs", 0o755)

	writers := []io.Writer{os.Stdout}
	if os.Getenv("FILE_LOG") != "0" {
		writers = append(writers, &lumberjack.Logger{
			Filename:   "logs/app.log",
			MaxSize:    50, // megabytes
			MaxBackups: 14,
			MaxAge:     30, // days
			Compress:   true,
		})
	}
	multi := io.MultiWriter(writers...)

	level := slog.LevelInfo
	switch strings.ToLower(os.Getenv("LOG_LEVEL")) {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	}

	h := slog.NewJSONHandler(multi, &slog.HandlerOptions{
		Level:       level,
		ReplaceAttr: redact,
	})

	logger = slog.New(h).With(
		"service", envOr("SERVICE_NAME", "receipts-quickstart-go"),
		"env", envOr("APP_ENV", "local"),
		"version", envOr("APP_VERSION", "0.0.1"),
	)
	slog.SetDefault(logger)
}

// 2. Correlation context.

func ctxLogger(ctx context.Context) *slog.Logger {
	l := logger
	if v, ok := ctx.Value(correlationKey).(string); ok {
		l = l.With("correlation_id", v)
	}
	if v, ok := ctx.Value(requestKey).(string); ok {
		l = l.With("request_id", v)
	}
	return l
}

// 3. Middleware + status capture.

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (sr *statusRecorder) WriteHeader(code int) {
	sr.status = code
	sr.ResponseWriter.WriteHeader(code)
}

func correlationMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		corrID := r.Header.Get("X-Correlation-Id")
		if corrID == "" {
			corrID = uuid.NewString()
		}
		reqID := uuid.NewString()
		ctx := context.WithValue(r.Context(), correlationKey, corrID)
		ctx = context.WithValue(ctx, requestKey, reqID)
		w.Header().Set("X-Correlation-Id", corrID)
		w.Header().Set("X-Request-Id", reqID)

		start := time.Now()
		log := ctxLogger(ctx).With(
			"operation", "http.request",
			"method", r.Method,
			"path", r.URL.Path,
		)
		log.InfoContext(ctx, "http.request", "status", "started")

		sr := &statusRecorder{ResponseWriter: w, status: 200}
		next(sr, r.WithContext(ctx))

		status := "success"
		if sr.status >= 400 {
			status = "failed"
		}
		log.InfoContext(ctx, "http.request",
			"status", status,
			"status_code", sr.status,
			"duration_ms", time.Since(start).Milliseconds(),
		)
	}
}

// 4. Handlers.

func helloHandler(w http.ResponseWriter, r *http.Request) {
	log := ctxLogger(r.Context())
	log.InfoContext(r.Context(), "demo.hello",
		"operation", "demo.hello", "step", "greeting")
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "hello": "world"})
}

func errorHandler(w http.ResponseWriter, r *http.Request) {
	log := ctxLogger(r.Context())
	log.ErrorContext(r.Context(), "demo.error",
		"operation", "demo.error",
		"error_class", "business",
		"error_code", "E_BIZ_DEMO_ERROR",
		"debug_context", map[string]any{"reason": "on-purpose for the demo"},
	)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnprocessableEntity)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error_code": "E_BIZ_DEMO_ERROR",
		"message":    "demo error",
	})
}

func slowHandler(w http.ResponseWriter, r *http.Request) {
	log := ctxLogger(r.Context())
	wait := time.Duration(100+rand.Intn(200)) * time.Millisecond
	log.InfoContext(r.Context(), "demo.slow",
		"operation", "demo.slow", "status", "started")
	time.Sleep(wait)
	log.InfoContext(r.Context(), "demo.slow",
		"operation", "demo.slow", "status", "success",
		"duration_ms", wait.Milliseconds())
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"ok":         true,
		"waited_ms":  wait.Milliseconds(),
	})
}

// 5. Server with graceful shutdown.

func main() {
	port := envOr("PORT", "3002")

	mux := http.NewServeMux()
	mux.HandleFunc("/hello", correlationMiddleware(helloHandler))
	mux.HandleFunc("/error", correlationMiddleware(errorHandler))
	mux.HandleFunc("/slow", correlationMiddleware(slowHandler))

	srv := &http.Server{Addr: ":" + port, Handler: mux}

	logger.Info("app.start",
		"operation", "app.start", "status", "success", "port", port)

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("app.failed",
				"operation", "app.failed", "error", err.Error())
			os.Exit(1)
		}
	}()

	sig := <-stop
	logger.Info("app.shutdown",
		"operation", "app.shutdown", "status", "started", "signal", sig.String())

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(ctx)

	logger.Info("app.shutdown",
		"operation", "app.shutdown", "status", "success")
}
