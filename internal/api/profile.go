package api

import (
	"context"

	"gotick/internal/oas"
)

// profileHandler serves the Profile operations, across every audience that exposes them.
type profileHandler struct{ deps }

// Compile-time check for profileHandler.
var _ oas.ProfileHandler = (*profileHandler)(nil)

// GetMyProfile implements [oas.ProfileHandler].
func (h *profileHandler) GetMyProfile(ctx context.Context) (oas.GetMyProfileRes, error) {
	panic("unimplemented")
}
