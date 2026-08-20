package service

import (
	"context"
	"log/slog"

	"gotick/internal/database"
)

type StaffStore interface {
	ListPlatformStaff(ctx context.Context) ([]database.ListPlatformStaffRow, error)
}

type Staff struct {
	store  StaffStore
	logger *slog.Logger
}

func NewStaff(store StaffStore, logger *slog.Logger) *Staff {
	return &Staff{store: store, logger: logger.With("service", "staff")}
}

func (s *Staff) List(ctx context.Context) ([]database.ListPlatformStaffRow, error) {
	return s.store.ListPlatformStaff(ctx)
}
