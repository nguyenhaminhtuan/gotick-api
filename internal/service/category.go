package service

import (
	"context"
	"log/slog"

	"gotick/internal/database"
)

type CategoryStore interface {
	GetCategories(ctx context.Context) ([]database.Category, error)
	GetAllCategories(ctx context.Context) ([]database.Category, error)
	GetCategory(ctx context.Context, id int64) (database.Category, error)
	InsertCategory(ctx context.Context, arg database.InsertCategoryParams) (database.Category, error)
	UpdateCategory(ctx context.Context, arg database.UpdateCategoryParams) (database.Category, error)
	ActivateCategory(ctx context.Context, id int64) (database.Category, error)
	DeactivateCategory(ctx context.Context, id int64) (database.Category, error)
}

type Categories struct {
	store  CategoryStore
	uow    UnitOfWork
	logger *slog.Logger
}

func NewCategories(store CategoryStore, uow UnitOfWork, logger *slog.Logger) *Categories {
	return &Categories{
		store:  store,
		uow:    uow,
		logger: logger.With("service", "categories"),
	}
}

type CategoryInput struct {
	Name         string
	Slug         string
	Icon         *string
	DisplayOrder int64
}

var (
	errCategoryNotFound  = xerrors.NotFound.New("CATEGORY_NOT_FOUND", "The requested category does not exist.")
	errCategorySlugTaken = xerrors.Conflict.New("CATEGORY_SLUG_TAKEN", "Another category already uses this slug.")
)

func (s *Categories) Active(ctx context.Context) ([]database.Category, error) {
	return s.store.GetCategories(ctx)
}

func (s *Categories) All(ctx context.Context) ([]database.Category, error) {
	return s.store.GetAllCategories(ctx)
}

func (s *Categories) Get(ctx context.Context, id int64) (database.Category, error) {
	category, err := s.store.GetCategory(ctx, id)
	if err != nil {
		if database.IsNoRows(err) {
			return database.Category{}, errCategoryNotFound
		}
		return database.Category{}, err
	}
	return category, nil
}

func (s *Categories) Create(ctx context.Context, in CategoryInput) (database.Category, error) {
	s.logger.DebugContext(ctx, "creating category", slog.Any("input", in))

	var category database.Category
	err := s.uow.RunInTx(ctx, func(tx Stores) error {
		created, err := tx.Categories.InsertCategory(ctx, database.InsertCategoryParams(in))
		if err != nil {
			if database.IsUniqueViolation(err) {
				return errCategorySlugTaken
			}
			return err
		}
		category = created
		return nil
	})
	if err != nil {
		return database.Category{}, err
	}

	s.logger.InfoContext(ctx, "category created", slog.Int64("category_id", category.ID))
	return category, nil
}

func (s *Categories) Update(ctx context.Context, id int64, in CategoryInput) (database.Category, error) {
	s.logger.DebugContext(ctx, "updating category",
		slog.Int64("category_id", id),
		slog.Any("input", in),
	)

	var category database.Category
	err := s.uow.RunInTx(ctx, func(tx Stores) error {
		updated, err := tx.Categories.UpdateCategory(ctx, database.UpdateCategoryParams{
			ID:           id,
			Name:         in.Name,
			Slug:         in.Slug,
			Icon:         in.Icon,
			DisplayOrder: in.DisplayOrder,
		})
		if err != nil {
			switch {
			case database.IsNoRows(err):
				return errCategoryNotFound
			case database.IsUniqueViolation(err):
				return errCategorySlugTaken
			default:
				return err
			}
		}
		category = updated
		return nil
	})
	if err != nil {
		return database.Category{}, err
	}

	s.logger.InfoContext(ctx, "category updated", slog.Int64("category_id", id))
	return category, nil
}

func (s *Categories) Activate(ctx context.Context, id int64) (database.Category, error) {
	return s.changeStatus(ctx, id, "active",
		func(tx Stores) (database.Category, error) { return tx.Categories.ActivateCategory(ctx, id) },
		xerrors.Conflict.New("CATEGORY_ALREADY_ACTIVE", "The category is already active."),
	)
}

func (s *Categories) Deactivate(ctx context.Context, id int64) (database.Category, error) {
	return s.changeStatus(ctx, id, "inactive",
		func(tx Stores) (database.Category, error) { return tx.Categories.DeactivateCategory(ctx, id) },
		xerrors.Conflict.New("CATEGORY_ALREADY_INACTIVE", "The category is already inactive."),
	)
}

func (s *Categories) changeStatus(
	ctx context.Context,
	id int64,
	status string,
	update func(Stores) (database.Category, error),
	errAlreadySet *Error,
) (database.Category, error) {
	var category database.Category
	err := s.uow.RunInTx(ctx, func(tx Stores) error {
		changed, err := update(tx)
		if err == nil {
			category = changed
			return nil
		}
		if !database.IsNoRows(err) {
			return err
		}

		if _, err := tx.Categories.GetCategory(ctx, id); err != nil {
			if database.IsNoRows(err) {
				return errCategoryNotFound
			}
			return err
		}
		return errAlreadySet
	})
	if err != nil {
		return database.Category{}, err
	}

	s.logger.InfoContext(ctx, "category status changed",
		slog.Int64("category_id", id),
		slog.String("status", status),
	)
	return category, nil
}
