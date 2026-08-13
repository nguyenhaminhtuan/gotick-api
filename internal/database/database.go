package database

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	*Queries

	pool *pgxpool.Pool
}

func NewDB(pool *pgxpool.Pool) *DB {
	return &DB{
		Queries: New(pool),
		pool:    pool,
	}
}

func (db *DB) WithTx(ctx context.Context, fn func(*Queries) error) error {
	tx, err := db.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}

	// A rollback after a successful commit is a no-op that reports
	// pgx.ErrTxClosed, so the error is deliberately dropped.
	defer func() { _ = tx.Rollback(context.WithoutCancel(ctx)) }()

	if err := fn(db.Queries.WithTx(tx)); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transaction: %w", err)
	}
	return nil
}

func (db *DB) Close() {
	db.pool.Close()
}
