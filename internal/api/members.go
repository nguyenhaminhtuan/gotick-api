package api

import (
	"context"

	"gotick/internal/oas"
)

// membersHandler serves the organizer membership operations.
type membersHandler struct{}

// Compile-time check for membersHandler.
var _ oas.MembersHandler = (*membersHandler)(nil)

// AddOrgMember implements [oas.MembersHandler].
func (h *membersHandler) AddOrgMember(ctx context.Context, req *oas.AddOrganizerMemberRequest, params oas.AddOrgMemberParams) (oas.AddOrgMemberRes, error) {
	panic("unimplemented")
}

// ListOrgMembers implements [oas.MembersHandler].
func (h *membersHandler) ListOrgMembers(ctx context.Context, params oas.ListOrgMembersParams) (oas.ListOrgMembersRes, error) {
	panic("unimplemented")
}

// RemoveOrgMember implements [oas.MembersHandler].
func (h *membersHandler) RemoveOrgMember(ctx context.Context, params oas.RemoveOrgMemberParams) (oas.RemoveOrgMemberRes, error) {
	panic("unimplemented")
}

// UpdateOrgMember implements [oas.MembersHandler].
func (h *membersHandler) UpdateOrgMember(ctx context.Context, req *oas.UpdateOrganizerMemberRequest, params oas.UpdateOrgMemberParams) (oas.UpdateOrgMemberRes, error) {
	panic("unimplemented")
}
