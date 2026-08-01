package auth

import (
	"context"
	"fmt"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

type firebaseVerifier struct {
	client *auth.Client
}

// Compile-time check for firebaseVerifier.
var _ Verifier = (*firebaseVerifier)(nil)

func NewFirebaseVerifier(ctx context.Context) (Verifier, error) {
	client, err := newFirebaseClient(ctx)
	if err != nil {
		return nil, err
	}
	return &firebaseVerifier{client: client}, nil
}

func (v *firebaseVerifier) Verify(ctx context.Context, token string) (Principal, error) {
	decoded, err := v.client.VerifyIDToken(ctx, token)
	if err != nil {
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
