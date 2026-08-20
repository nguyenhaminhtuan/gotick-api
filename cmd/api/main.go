package main

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"gotick/internal/api"
	"gotick/internal/auth"
	"gotick/internal/config"
	"gotick/internal/database"
	"gotick/internal/log"
	"gotick/internal/server"
	"gotick/internal/service"
)

func main() {
	if err := run(context.Background()); err != nil {
		slog.Error("failed to bootstrap", slog.Any("error", err))
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	config, err := config.Load()
	if err != nil {
		return err
	}

	logger, err := log.New(config.LogConfig)
	if err != nil {
		return err
	}
	// Anything reaching for slog's default logger, including slogctx.FromCtx
	// when no logger was put on the context, writes to the same place.
	slog.SetDefault(logger)

	// Registered before the blocking init below so a signal arriving during
	// startup unwinds through these defers instead of killing the process.
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	pool, err := database.NewPostgresPool(ctx, config.DBConfig, logger)
	if err != nil {
		return err
	}
	db := database.NewDB(pool)
	defer db.Close()

	verifier, err := auth.NewFirebaseVerifier(ctx)
	if err != nil {
		return err
	}

	uow := service.NewUnitOfWork(db)

	categories := service.NewCategories(db, uow, logger)
	accounts := service.NewAccounts(db, verifier, logger)
	staff := service.NewStaff(db, logger)

	handler := api.NewHandler(categories, accounts, staff, logger, verifier)

	srv, err := server.NewServer(config, logger, handler)
	if err != nil {
		return err
	}

	// Shutdown waits for handlers but never cancels them, so requests that
	// outlive the grace period would still be querying when db.Close runs.
	// Handlers inherit this context; cancelling it makes them give up first.
	// Deferred last, so it also runs before db.Close.
	requestCtx, cancelRequests := context.WithCancel(context.WithoutCancel(ctx))
	defer cancelRequests()
	srv.BaseContext = func(net.Listener) context.Context { return requestCtx }

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("http server started", slog.String("address", srv.Addr))
		serveErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		// Only reachable when the listener itself fails; a shutdown-induced
		// ErrServerClosed arrives after the ctx.Done branch has already run.
		if !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	case <-ctx.Done():
	}

	// Restoring the default handler makes a second Ctrl+C kill the process.
	logger.Info("shutting down gracefully, press Ctrl+C again to force")
	stop()

	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), config.ServerConfig.ShutdownTimeout())
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("shutdown timed out, abandoning in-flight requests", slog.Any("error", err))
	}

	logger.Info("graceful shutdown complete")
	return nil
}
