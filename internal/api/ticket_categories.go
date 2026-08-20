package api

import (
	"context"

	"gotick/internal/oas"
)

// ticketCategoriesHandler serves the TicketCategories operations, across every audience that exposes them.
type ticketCategoriesHandler struct{}

// Compile-time check for ticketCategoriesHandler.
var _ oas.TicketCategoriesHandler = (*ticketCategoriesHandler)(nil)

// CreateOrgTicketCategory implements [oas.TicketCategoriesHandler].
func (h *ticketCategoriesHandler) CreateOrgTicketCategory(ctx context.Context, params oas.CreateOrgTicketCategoryParams) (oas.CreateOrgTicketCategoryRes, error) {
	panic("unimplemented")
}

// GetOrgTicketCategory implements [oas.TicketCategoriesHandler].
func (h *ticketCategoriesHandler) GetOrgTicketCategory(ctx context.Context, params oas.GetOrgTicketCategoryParams) (oas.GetOrgTicketCategoryRes, error) {
	panic("unimplemented")
}

// ListOrgTicketCategories implements [oas.TicketCategoriesHandler].
func (h *ticketCategoriesHandler) ListOrgTicketCategories(ctx context.Context, params oas.ListOrgTicketCategoriesParams) (oas.ListOrgTicketCategoriesRes, error) {
	panic("unimplemented")
}

// ListPublicTicketCategories implements [oas.TicketCategoriesHandler].
func (h *ticketCategoriesHandler) ListPublicTicketCategories(ctx context.Context, params oas.ListPublicTicketCategoriesParams) (oas.ListPublicTicketCategoriesRes, error) {
	panic("unimplemented")
}

// UpdateOrgTicketCategory implements [oas.TicketCategoriesHandler].
func (h *ticketCategoriesHandler) UpdateOrgTicketCategory(ctx context.Context, params oas.UpdateOrgTicketCategoryParams) (oas.UpdateOrgTicketCategoryRes, error) {
	panic("unimplemented")
}
