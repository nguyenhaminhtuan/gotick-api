package api

import (
	"context"

	"gotick/internal/oas"
)

// organizerApplicationsHandler serves the OrganizerApplications operations, across every audience that exposes them.
type organizerApplicationsHandler struct{ deps }

// Compile-time check for organizerApplicationsHandler.
var _ oas.OrganizerApplicationsHandler = (*organizerApplicationsHandler)(nil)

// ApproveAdminOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) ApproveAdminOrganizerApplication(ctx context.Context, params oas.ApproveAdminOrganizerApplicationParams) (oas.ApproveAdminOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// CreateMyOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) CreateMyOrganizerApplication(ctx context.Context) (oas.CreateMyOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// GetMyOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) GetMyOrganizerApplication(ctx context.Context, params oas.GetMyOrganizerApplicationParams) (oas.GetMyOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// ListAdminOrganizerApplications implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) ListAdminOrganizerApplications(ctx context.Context, params oas.ListAdminOrganizerApplicationsParams) (oas.ListAdminOrganizerApplicationsRes, error) {
	panic("unimplemented")
}

// ListMyOrganizerApplications implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) ListMyOrganizerApplications(ctx context.Context, params oas.ListMyOrganizerApplicationsParams) (oas.ListMyOrganizerApplicationsRes, error) {
	panic("unimplemented")
}

// RejectAdminOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) RejectAdminOrganizerApplication(ctx context.Context, params oas.RejectAdminOrganizerApplicationParams) (oas.RejectAdminOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// RequestChangesAdminOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) RequestChangesAdminOrganizerApplication(ctx context.Context, params oas.RequestChangesAdminOrganizerApplicationParams) (oas.RequestChangesAdminOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// ResubmitMyOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) ResubmitMyOrganizerApplication(ctx context.Context, params oas.ResubmitMyOrganizerApplicationParams) (oas.ResubmitMyOrganizerApplicationRes, error) {
	panic("unimplemented")
}

// UpdateMyOrganizerApplication implements [oas.OrganizerApplicationsHandler].
func (h *organizerApplicationsHandler) UpdateMyOrganizerApplication(ctx context.Context, params oas.UpdateMyOrganizerApplicationParams) (oas.UpdateMyOrganizerApplicationRes, error) {
	panic("unimplemented")
}
