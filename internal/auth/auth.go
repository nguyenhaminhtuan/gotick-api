package auth

import (
	"context"
	"errors"
)

var ErrUserDisabled = errors.New("user disabled")

const (
	AccountClaim = "account_id"
	StaffClaim   = "staff"
)

const (
	StaffRoleOwner = "owner"
	StaffRoleStaff = "staff"
)

type Principal struct {
	Subject string
	Email   string
	Claims  map[string]any
}

func (p Principal) Claim(name string) string {
	s, ok := p.Claims[name].(string)
	if !ok {
		return ""
	}
	return s
}

func (p Principal) BoolClaim(name string) bool {
	b, _ := p.Claims[name].(bool)
	return b
}

type Verifier interface {
	Verify(ctx context.Context, token string) (Principal, error)
}

// ClaimWriter writes one claim at a time on purpose. Two things stamp claims
// on an identity — registration owns the account, granting owns the role — and
// neither should have to know or preserve what the other wrote.
type ClaimWriter interface {
	SetAccountClaim(ctx context.Context, subject, accountID string) error
	SetStaffClaim(ctx context.Context, subject, role string) error
	RevokeTokens(ctx context.Context, subject string) error
}

// User is an identity as the provider holds it, for the rare caller that has a
// subject and no token to read it from.
type User struct {
	Subject  string
	Email    string
	FullName string
	Avatar   string
	Phone    string
}

type UserReader interface {
	GetUser(ctx context.Context, subject string) (User, error)
}

// Provider is everything the identity provider can do. Callers take the
// narrower interface they need; only construction names this one.
type Provider interface {
	Verifier
	ClaimWriter
	UserReader
}

type principalKey struct{}

func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}

func PrincipalFrom(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}
