package database

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Store is the database as the rest of the application uses it: every generated
// query, plus a way to group several into one unit of work.
//
// Tx hands the callback a Store rather than a Queries so the callback can do
// anything the caller could, including running further work that opens its own
// transaction — that inner call joins this one instead of starting a second.
type Store interface {
	Querier

	Tx(ctx context.Context, fn func(Store) error) error
}

// DB owns the pool. It is the only Store that can begin a transaction.
type DB struct {
	*Queries

	pool *pgxpool.Pool
}

var _ Store = (*DB)(nil)

func NewDB(pool *pgxpool.Pool) *DB {
	return &DB{
		Queries: New(pool),
		pool:    pool,
	}
}

func (db *DB) Tx(ctx context.Context, fn func(Store) error) error {
	tx, err := db.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}

	// A rollback after a successful commit is a no-op that reports
	// pgx.ErrTxClosed, so the error is deliberately dropped.
	defer func() { _ = tx.Rollback(context.WithoutCancel(ctx)) }()

	if err := fn(&txStore{Queries: db.WithTx(tx)}); err != nil {
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

// txStore is a Store bound to an open transaction.
type txStore struct {
	*Queries
}

var _ Store = (*txStore)(nil)

// Tx joins the transaction already in progress. Beginning a second one from
// inside the first would deadlock on the same connection, and a nested unit of
// work that commits independently is not what any caller means.
func (s *txStore) Tx(ctx context.Context, fn func(Store) error) error {
	return fn(s)
}
