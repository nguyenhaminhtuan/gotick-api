package auth

import (
	"context"
	"fmt"
	"maps"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

type firebaseVerifier struct {
	client *auth.Client
}

var (
	_ Verifier    = (*firebaseVerifier)(nil)
	_ ClaimWriter = (*firebaseVerifier)(nil)
	_ UserReader  = (*firebaseVerifier)(nil)
)

func NewFirebaseVerifier(ctx context.Context) (Provider, error) {
	client, err := newFirebaseClient(ctx)
	if err != nil {
		return nil, err
	}
	return &firebaseVerifier{client: client}, nil
}

func (v *firebaseVerifier) Verify(ctx context.Context, token string) (Principal, error) {
	decoded, err := v.client.VerifyIDTokenAndCheckRevoked(ctx, token)
	if err != nil {
		if auth.IsUserDisabled(err) {
			return Principal{}, fmt.Errorf("%w: %w", ErrUserDisabled, err)
		}
		return Principal{}, fmt.Errorf("%w", err)
	}

	subject := decoded.UID
	if subject == "" {
		subject = decoded.Subject
	}
	email, _ := decoded.Claims["email"].(string)

	return Principal{
		Subject: subject,
		Email:   email,
		Claims:  decoded.Claims,
	}, nil
}

func (v *firebaseVerifier) GetUser(ctx context.Context, subject string) (User, error) {
	record, err := v.client.GetUser(ctx, subject)
	if err != nil {
		return User{}, fmt.Errorf("get user: %w", err)
	}

	return User{
		Subject:  record.UID,
		Email:    record.Email,
		FullName: record.DisplayName,
		Avatar:   record.PhotoURL,
		Phone:    record.PhoneNumber,
	}, nil
}

func (v *firebaseVerifier) SetAccountClaim(ctx context.Context, subject, accountID string) error {
	return v.mergeClaims(ctx, subject, map[string]any{AccountClaim: accountID})
}

func (v *firebaseVerifier) SetStaffClaim(ctx context.Context, subject, role string) error {
	// No role is the absence of the claim rather than an empty one, which is
	// also how a reader that finds nothing already interprets it.
	if role == "" {
		return v.mergeClaims(ctx, subject, map[string]any{StaffClaim: nil})
	}
	return v.mergeClaims(ctx, subject, map[string]any{StaffClaim: role})
}

// mergeClaims keeps every claim it was not given. SetCustomUserClaims replaces
// the whole set, so writing one claim means reading the rest back first; a nil
// value drops its claim instead of storing one.
func (v *firebaseVerifier) mergeClaims(ctx context.Context, subject string, set map[string]any) error {
	record, err := v.client.GetUser(ctx, subject)
	if err != nil {
		return fmt.Errorf("get user: %w", err)
	}

	claims := make(map[string]any, len(record.CustomClaims)+len(set))
	maps.Copy(claims, record.CustomClaims)
	for name, value := range set {
		if value == nil {
			delete(claims, name)
			continue
		}
		claims[name] = value
	}

	if err := v.client.SetCustomUserClaims(ctx, subject, claims); err != nil {
		return fmt.Errorf("set account claims: %w", err)
	}
	return nil
}

func (v *firebaseVerifier) RevokeTokens(ctx context.Context, subject string) error {
	if err := v.client.RevokeRefreshTokens(ctx, subject); err != nil {
		return fmt.Errorf("revoke tokens: %w", err)
	}
	return nil
}

func newFirebaseClient(ctx context.Context) (*auth.Client, error) {
	var (
		cfg  *firebase.Config
		opts []option.ClientOption
	)

	if host := os.Getenv("FIREBASE_AUTH_EMULATOR_HOST"); host != "" {
		cfg = &firebase.Config{}
		opts = append(opts, option.WithoutAuthentication())
	}

	app, err := firebase.NewApp(ctx, cfg, opts...)
	if err != nil {
		return nil, fmt.Errorf("init firebase app: %w", err)
	}
	return app.Auth(ctx)
}
