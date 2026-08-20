package api

import (
	"context"

	"gotick/internal/database"
	"gotick/internal/oas"
	"gotick/internal/service"
)

type staffHandler struct{ staff *service.Staff }

var _ oas.StaffHandler = (*staffHandler)(nil)

// ListAdminStaff implements [oas.StaffHandler]. Readable by any staff: knowing
// who else operates the platform is not a privilege worth gating.
func (h *staffHandler) ListAdminStaff(ctx context.Context) (oas.ListAdminStaffRes, error) {
	staff, err := h.staff.List(ctx)
	if err != nil {
		return nil, err
	}
	res := listResponse[oas.PlatformStaffList](staff, platformStaffResponse)
	return &res, nil
}

func platformStaffResponse(r *database.ListPlatformStaffRow) *oas.PlatformStaff {
	staff := &oas.PlatformStaff{
		Account: oas.AccountSummary{
			ID:       oas.UUID(r.AccountID),
			FullName: r.FullName,
			Email:    r.Email,
			Avatar:   r.Avatar,
		},
		Role:      oas.PlatformStaffRole(r.Role),
		CreatedAt: r.CreatedAt,
		UpdatedAt: r.UpdatedAt,
	}
	if r.GrantedBy != nil {
		staff.GrantedBy = oas.NewOptUUID(oas.UUID(*r.GrantedBy))
	}
	return staff
}
