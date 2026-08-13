package api

import (
	"context"

	"gotick/internal/oas"
)

// organizersHandler serves the Organizers operations, across every audience that exposes them.
type organizersHandler struct{ deps }

// Compile-time check for organizersHandler.
var _ oas.OrganizersHandler = (*organizersHandler)(nil)

// ActivateAdminOrganizer implements [oas.OrganizersHandler].
func (h *organizersHandler) ActivateAdminOrganizer(ctx context.Context, params oas.ActivateAdminOrganizerParams) (oas.ActivateAdminOrganizerRes, error) {
	panic("unimplemented")
}

// GetPublicOrganizer implements [oas.OrganizersHandler].
func (h *organizersHandler) GetPublicOrganizer(ctx context.Context, params oas.GetPublicOrganizerParams) (oas.GetPublicOrganizerRes, error) {
	panic("unimplemented")
}

// ListAdminOrganizers implements [oas.OrganizersHandler].
func (h *organizersHandler) ListAdminOrganizers(ctx context.Context, params oas.ListAdminOrganizersParams) (oas.ListAdminOrganizersRes, error) {
	panic("unimplemented")
}

// ListPublicOrganizers implements [oas.OrganizersHandler].
func (h *organizersHandler) ListPublicOrganizers(ctx context.Context, params oas.ListPublicOrganizersParams) (oas.ListPublicOrganizersRes, error) {
	panic("unimplemented")
}

// SuspendAdminOrganizer implements [oas.OrganizersHandler].
func (h *organizersHandler) SuspendAdminOrganizer(ctx context.Context, params oas.SuspendAdminOrganizerParams) (oas.SuspendAdminOrganizerRes, error) {
	panic("unimplemented")
}
