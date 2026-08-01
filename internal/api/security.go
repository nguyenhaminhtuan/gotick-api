package api

import (
	"context"
	"gotick/internal/auth"
	"gotick/internal/oas"
	"log/slog"

	slogctx "github.com/veqryn/slog-context"
)

// Compile-time check for Handler.
var _ oas.SecurityHandler = (*Handler)(nil)

// HandleBearerAuth implements [oas.SecurityHandler]. Returning an APIError lets
func (h *Handler) HandleBearerAuth(ctx context.Context, _ oas.OperationName, t oas.BearerAuth) (context.Context, error) {
	principal, err := h.verifier.Verify(ctx, t.GetToken())
	if err != nil {
		return ctx, err
	}

	ctx = slogctx.Prepend(ctx, slog.String("user_id", principal.Subject))
	return auth.WithPrincipal(ctx, principal), nil
}
