package api

import (
	"context"

	"gotick/internal/database"
	"gotick/internal/oas"
	"gotick/internal/service"
)

type categoriesHandler struct{ categories *service.Categories }

var _ oas.CategoriesHandler = (*categoriesHandler)(nil)

func (h *categoriesHandler) ActivateAdminCategory(ctx context.Context, params oas.ActivateAdminCategoryParams) (oas.ActivateAdminCategoryRes, error) {
	category, err := h.categories.Activate(ctx, params.CategoryId)
	if err != nil {
		return nil, err
	}
	return categoryResponse(&category), nil
}

func (h *categoriesHandler) DeactivateAdminCategory(ctx context.Context, params oas.DeactivateAdminCategoryParams) (oas.DeactivateAdminCategoryRes, error) {
	category, err := h.categories.Deactivate(ctx, params.CategoryId)
	if err != nil {
		return nil, err
	}
	return categoryResponse(&category), nil
}

func (h *categoriesHandler) CreateAdminCategory(ctx context.Context, req *oas.CreateCategoryRequest) (oas.CreateAdminCategoryRes, error) {
	category, err := h.categories.Create(ctx, service.CategoryInput{
		Name:         req.Name,
		Slug:         string(req.Slug),
		Icon:         unwrapOpt(req.Icon),
		DisplayOrder: req.DisplayOrder.Or(0),
	})
	if err != nil {
		return nil, err
	}
	return categoryResponse(&category), nil
}

func (h *categoriesHandler) UpdateAdminCategory(ctx context.Context, req *oas.UpdateCategoryRequest, params oas.UpdateAdminCategoryParams) (oas.UpdateAdminCategoryRes, error) {
	category, err := h.categories.Update(ctx, params.CategoryId, service.CategoryInput{
		Name:         req.Name,
		Slug:         string(req.Slug),
		Icon:         unwrapOpt(req.Icon),
		DisplayOrder: req.DisplayOrder.Or(0),
	})
	if err != nil {
		return nil, err
	}
	return categoryResponse(&category), nil
}

func (h *categoriesHandler) GetAdminCategory(ctx context.Context, params oas.GetAdminCategoryParams) (oas.GetAdminCategoryRes, error) {
	category, err := h.categories.Get(ctx, params.CategoryId)
	if err != nil {
		return nil, err
	}
	return categoryResponse(&category), nil
}

func (h *categoriesHandler) ListAdminCategories(ctx context.Context) (oas.ListAdminCategoriesRes, error) {
	categories, err := h.categories.All(ctx)
	if err != nil {
		return nil, err
	}
	res := listResponse[oas.CategoryList](categories, categoryResponse)
	return &res, nil
}

func (h *categoriesHandler) ListPublicCategories(ctx context.Context) (oas.ListPublicCategoriesRes, error) {
	categories, err := h.categories.Active(ctx)
	if err != nil {
		return nil, err
	}
	res := listResponse[oas.PublicCategoryList](categories, publicCategoryResponse)
	return &res, nil
}

func categoryResponse(c *database.Category) *oas.Category {
	return &oas.Category{
		ID:           c.ID,
		Name:         c.Name,
		Slug:         oas.Slug(c.Slug),
		Icon:         wrapOpt(c.Icon, oas.NewOptString),
		DisplayOrder: c.DisplayOrder,
		Status:       oas.CategoryStatus(c.Status),
		CreatedAt:    c.CreatedAt,
		UpdatedAt:    c.UpdatedAt,
	}
}

func publicCategoryResponse(c *database.Category) *oas.PublicCategory {
	return &oas.PublicCategory{
		ID:           c.ID,
		Name:         c.Name,
		Slug:         oas.Slug(c.Slug),
		Icon:         wrapOpt(c.Icon, oas.NewOptString),
		DisplayOrder: c.DisplayOrder,
	}
}
