package api

import (
	"context"
	"gotick/internal/database"
	"gotick/internal/oas"
)

// categoriesHandler serves the Categories operations, across every audience that exposes them.
type categoriesHandler struct{ deps }

// Compile-time check for categoriesHandler.
var _ oas.CategoriesHandler = (*categoriesHandler)(nil)

// ActivateAdminCategory implements [oas.CategoriesHandler].
func (h *categoriesHandler) ActivateAdminCategory(ctx context.Context, params oas.ActivateAdminCategoryParams) (oas.ActivateAdminCategoryRes, error) {
	panic("unimplemented")
}

// CreateAdminCategory implements [oas.CategoriesHandler].
func (h *categoriesHandler) CreateAdminCategory(ctx context.Context) (oas.CreateAdminCategoryRes, error) {
	panic("unimplemented")
}

// DeactivateAdminCategory implements [oas.CategoriesHandler].
func (h *categoriesHandler) DeactivateAdminCategory(ctx context.Context, params oas.DeactivateAdminCategoryParams) (oas.DeactivateAdminCategoryRes, error) {
	panic("unimplemented")
}

// GetAdminCategory implements [oas.CategoriesHandler].
func (h *categoriesHandler) GetAdminCategory(ctx context.Context, params oas.GetAdminCategoryParams) (oas.GetAdminCategoryRes, error) {
	panic("unimplemented")
}

// ListAdminCategories implements [oas.CategoriesHandler].
func (h *categoriesHandler) ListAdminCategories(ctx context.Context) (oas.ListAdminCategoriesRes, error) {
	categories, err := h.db.GetCategories(ctx)
	if err != nil {
		return nil, err
	}
	res := mapSlice[oas.CategoryList](categories, toCategory)
	return &res, nil
}

// ListPublicCategories implements [oas.CategoriesHandler].
func (h *categoriesHandler) ListPublicCategories(ctx context.Context) (oas.ListPublicCategoriesRes, error) {
	categories, err := h.db.GetCategories(ctx)
	if err != nil {
		return nil, err
	}
	res := mapSlice[oas.PublicCategoryList](categories, toPublicCategory)
	return &res, nil
}

// UpdateAdminCategory implements [oas.CategoriesHandler].
func (h *categoriesHandler) UpdateAdminCategory(ctx context.Context, params oas.UpdateAdminCategoryParams) (oas.UpdateAdminCategoryRes, error) {
	panic("unimplemented")
}

func toCategory(c *database.Category) *oas.Category {
	return &oas.Category{
		ID:           int(c.ID),
		Name:         c.Name,
		Slug:         oas.Slug(c.Slug),
		Icon:         toOptString(c.Icon),
		DisplayOrder: int(c.DisplayOrder),
		Status:       oas.CategoryStatus(c.Status),
		CreatedAt:    c.CreatedAt,
		UpdatedAt:    c.UpdatedAt,
	}
}

func toPublicCategory(c *database.Category) *oas.PublicCategory {
	return &oas.PublicCategory{
		ID:           int(c.ID),
		Name:         c.Name,
		Slug:         oas.Slug(c.Slug),
		Icon:         toOptString(c.Icon),
		DisplayOrder: int(c.DisplayOrder),
	}
}
