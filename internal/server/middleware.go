package server

import (
	"encoding/json"
	"gotick/internal/oas"
	"log/slog"
	"net/http"
	"runtime/debug"
	"strconv"

	"github.com/felixge/httpsnoop"
	"github.com/rs/cors"
	slogctx "github.com/veqryn/slog-context"
)

type Middleware = func(http.Handler) http.Handler

func wrap(h http.Handler, middlewares ...Middleware) http.Handler {
	for i := len(middlewares) - 1; i >= 0; i-- {
		h = middlewares[i](h)
	}

	return h
}

func (s *server) accessLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		m := httpsnoop.CaptureMetrics(next, w, r)

		s.logger.InfoContext(r.Context(), "request completed",
			slog.String("method", r.Method),
			slog.String("path", r.URL.Path),
			slog.Int("status", m.Code),
			slog.Int64("size", m.Written),
			slog.String("duration", strconv.FormatFloat(m.Duration.Seconds(), 'f', -1, 64)+"s"),
		)
	})
}

func (s *server) cors() Middleware {
	return cors.New(cors.Options{
		AllowedOrigins: s.config.AllowedOrigins,
		AllowedMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
		},
		AllowedHeaders: []string{"Authorization", "Content-Type"},
		MaxAge:         300,
	}).Handler
}

func (s *server) injectLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r.WithContext(slogctx.NewCtx(r.Context(), s.logger)))
	})
}

// net/http recovers on its own but abandons the connection without a reply,
// so the client would otherwise see a dropped connection instead of an error.
func (s *server) recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			rec := recover()
			if rec == nil {
				return
			}

			// The documented way to abandon a response on purpose; it has to
			// keep going up to net/http.
			if rec == http.ErrAbortHandler {
				panic(rec)
			}

			s.logger.ErrorContext(r.Context(), "panic recovered",
				slog.Any("panic", rec),
				slog.String("stack", string(debug.Stack())),
			)

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			_ = json.NewEncoder(w).Encode(oas.Error{
				Error:   "InternalServerError",
				Message: "An unexpected error occurred. Please try again later.",
			})
		}()

		next.ServeHTTP(w, r)
	})
}
