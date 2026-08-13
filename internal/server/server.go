package server

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"

	"gotick/internal/config"
	"gotick/internal/oas"
)

type APIHandler interface {
	oas.Handler
	oas.SecurityHandler

	ErrorHandler(ctx context.Context, w http.ResponseWriter, r *http.Request, err error)
	NotFound(w http.ResponseWriter, r *http.Request)
	MethodNotAllowed(w http.ResponseWriter, r *http.Request, allowed string)
}

type server struct {
	config  *config.Config
	logger  *slog.Logger
	handler APIHandler
}

func NewServer(
	cfg *config.Config,
	logger *slog.Logger,
	handler APIHandler,
) (*http.Server, error) {
	srv := &server{
		config:  cfg,
		logger:  logger,
		handler: handler,
	}

	routes, err := srv.registerRoutes()
	if err != nil {
		return nil, err
	}

	return &http.Server{
		Addr:         fmt.Sprintf("%s:%d", cfg.Host, cfg.Port),
		Handler:      routes,
		IdleTimeout:  cfg.ServerConfig.IdleTimeout,
		ReadTimeout:  cfg.ServerConfig.ReadTimeout,
		WriteTimeout: cfg.ServerConfig.WriteTimeout,
	}, nil
}
