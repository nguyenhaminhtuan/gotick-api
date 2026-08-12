package database

import (
	"context"
	"fmt"
	"gotick/internal/config"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/tracelog"
	pgxslog "github.com/mcosta74/pgx-slog"
)

func NewPostgresPool(ctx context.Context, cfg config.DBConfig, logger *slog.Logger) (*pgxpool.Pool, error) {
	l := logger.With("component", "database")
	pgCfg, err := pgxpool.ParseConfig(cfg.DSN())
	if err != nil {
		return nil, fmt.Errorf("parse database pool config: %w", err)
	}

	logLevel := tracelog.LogLevelInfo
	if cfg.ShowSQL {
		logLevel = tracelog.LogLevelDebug
	}

	pgCfg.MinConns = cfg.MinConns
	pgCfg.MaxConns = cfg.MaxConns
	pgCfg.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeDescribeExec
	pgCfg.ConnConfig.Tracer = &tracelog.TraceLog{
		Logger:   pgxslog.NewLogger(l),
		LogLevel: logLevel,
	}

	pool, err := pgxpool.NewWithConfig(ctx, pgCfg)
	if err != nil {
		return nil, fmt.Errorf("create database pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return pool, nil
}
