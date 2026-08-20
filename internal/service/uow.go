package service

import (
	"context"

	"gotick/internal/database"
)

type Stores struct {
	Categories CategoryStore
	Accounts   AccountStore
	Staff      StaffStore
}

type UnitOfWork interface {
	RunInTx(ctx context.Context, fn func(Stores) error) error
}

type unitOfWork struct {
	db database.Store
}

func NewUnitOfWork(db database.Store) UnitOfWork {
	return unitOfWork{db: db}
}

func (u unitOfWork) RunInTx(ctx context.Context, fn func(Stores) error) error {
	return u.db.Tx(ctx, func(tx database.Store) error {
		return fn(Stores{
			Categories: tx,
			Accounts:   tx,
			Staff:      tx,
		})
	})
}
