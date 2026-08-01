package auth

import (
	"context"
)

type Principal struct {
	Subject string
	Email   string
	Claims  map[string]any
}

func (p Principal) Claim(name string) string {
	s, _ := p.Claims[name].(string)
	return s
}

type Verifier interface {
	Verify(ctx context.Context, token string) (Principal, error)
}

type principalKey struct{}

func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}

func PrincipalFrom(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}
