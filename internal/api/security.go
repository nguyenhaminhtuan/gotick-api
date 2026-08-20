package api

import (
	"context"
	"errors"
	"log/slog"

	"gotick/internal/auth"
	"gotick/internal/oas"

	"github.com/google/uuid"
	slogctx "github.com/veqryn/slog-context"
)

var _ oas.SecurityHandler = (*Handler)(nil)

var (
	errUnauthenticated      = unauthorized.New("UNAUTHENTICATED", "Authentication is required.")
	errAccountNotRegistered = forbidden.New("ACCOUNT_NOT_REGISTERED", "This identity has no account yet.")
	errAccountSuspended     = forbidden.New("ACCOUNT_SUSPENDED", "This account is suspended.")
	errNotPlatformStaff     = forbidden.New("NOT_PLATFORM_STAFF", "This account is not allowed to use the admin API.")
)

var setupOperations = map[oas.OperationName]bool{
	oas.CreateMyProfileOperation: true,
}

func (h *Handler) HandleBearerAuth(ctx context.Context, op oas.OperationName, t oas.BearerAuth) (context.Context, error) {
	ctx, principal, err := h.authenticate(ctx, t.GetToken())
	if err != nil {
		return ctx, err
	}

	if setupOperations[op] {
		return ctx, nil
	}

	ctx, _, err = h.accountID(ctx, principal)
	return ctx, err
}

func (h *Handler) HandleAdminAuth(ctx context.Context, _ oas.OperationName, t oas.AdminAuth) (context.Context, error) {
	ctx, principal, err := h.authenticate(ctx, t.GetToken())
	if err != nil {
		return ctx, err
	}

	ctx, _, err = h.accountID(ctx, principal)
	if err != nil {
		return ctx, err
	}

	role := principal.Claim(auth.StaffClaim)
	if role == "" {
		return ctx, errNotPlatformStaff
	}
	return withStaffRole(ctx, role), nil
}

func (h *Handler) authenticate(ctx context.Context, token string) (context.Context, auth.Principal, error) {
	principal, err := h.verifier.Verify(ctx, token)
	if err != nil {
		if errors.Is(err, auth.ErrUserDisabled) {
			return ctx, auth.Principal{}, errAccountSuspended
		}
		return ctx, auth.Principal{}, err
	}

	ctx = slogctx.Prepend(ctx, slog.String("user_id", principal.Subject))
	return auth.WithPrincipal(ctx, principal), principal, nil
}

func (h *Handler) accountID(ctx context.Context, principal auth.Principal) (context.Context, uuid.UUID, error) {
	claim := principal.Claim(auth.AccountClaim)
	if claim == "" {
		h.logger.DebugContext(ctx, "identity has no account yet")
		return ctx, uuid.Nil, errAccountNotRegistered
	}

	id, err := uuid.Parse(claim)
	if err != nil {
		h.logger.ErrorContext(ctx, "account claim is not a uuid", slog.String("claim", claim))
		return ctx, uuid.Nil, errAccountNotRegistered
	}

	ctx = slogctx.Prepend(ctx, slog.String("account_id", claim))
	return withAccountID(ctx, id), id, nil
}

type staffRoleKey struct{}

func withStaffRole(ctx context.Context, role string) context.Context {
	return context.WithValue(ctx, staffRoleKey{}, role)
}

func StaffRoleFrom(ctx context.Context) string {
	role, _ := ctx.Value(staffRoleKey{}).(string)
	return role
}

type accountIDKey struct{}

func withAccountID(ctx context.Context, id uuid.UUID) context.Context {
	return context.WithValue(ctx, accountIDKey{}, id)
}

func AccountIDFrom(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(accountIDKey{}).(uuid.UUID)
	return id, ok
}
