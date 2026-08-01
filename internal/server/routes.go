package server

import (
	"fmt"
	"gotick/internal/oas"
	"net/http"
)

func (s *server) registerRoutes() (http.Handler, error) {
	apiServer, err := oas.NewServer(s.handler, s.handler,
		oas.WithPathPrefix("/v1"),
		oas.WithErrorHandler(s.handler.ErrorHandler),
		oas.WithNotFound(s.handler.NotFound),
		oas.WithMethodNotAllowed(s.handler.MethodNotAllowed),
	)
	if err != nil {
		return nil, fmt.Errorf("create API server: %w", err)
	}

	middlewares := []Middleware{s.cors()}
	if s.config.IsLocal() {
		middlewares = append(middlewares, s.accessLog)
	}
	middlewares = append(middlewares,
		s.injectLogger,
		s.recoverer,
	)

	mux := http.NewServeMux()
	mux.Handle("/v1/", apiServer)
	mux.HandleFunc("GET /health", health)
	mux.HandleFunc("/", s.handler.NotFound)

	return wrap(mux, middlewares...), nil
}

func health(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write([]byte("ok"))
}
