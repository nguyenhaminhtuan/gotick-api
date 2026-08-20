package api

import (
	"context"

	"gotick/internal/auth"
	"gotick/internal/database"
	"gotick/internal/oas"
	"gotick/internal/service"
)

type profileHandler struct{ accounts *service.Accounts }

var _ oas.ProfileHandler = (*profileHandler)(nil)

func (h *profileHandler) GetMyProfile(ctx context.Context) (oas.GetMyProfileRes, error) {
	id, ok := AccountIDFrom(ctx)
	if !ok {
		return nil, errAccountNotRegistered
	}

	account, err := h.accounts.Get(ctx, id)
	if err != nil {
		if service.KindOf(err) == service.KindNotFound {
			return nil, errAccountNotRegistered
		}
		return nil, err
	}
	return myProfileResponse(&account), nil
}

func (h *profileHandler) CreateMyProfile(ctx context.Context, req *oas.CreateMyProfileRequest) (oas.CreateMyProfileRes, error) {
	principal, ok := auth.PrincipalFrom(ctx)
	if !ok {
		return nil, errUnauthenticated
	}

	account, err := h.accounts.SetupProfile(ctx, principal, service.SetupProfileInput{
		FullName: req.FullName,
	})
	if err != nil {
		return nil, err
	}
	return myProfileResponse(&account), nil
}

func myProfileResponse(a *database.Account) *oas.MyProfile {
	return &oas.MyProfile{
		ID:       oas.UUID(a.ID),
		FullName: a.FullName,
		Email:    a.Email,
		Avatar:   a.Avatar,
	}
}
