package service

import (
	"context"
	"log/slog"

	"gotick/internal/auth"
	"gotick/internal/database"

	"github.com/google/uuid"
)

type AccountStore interface {
	GetAccountByID(ctx context.Context, id uuid.UUID) (database.Account, error)
	InsertAccount(ctx context.Context, arg database.InsertAccountParams) (database.Account, error)
}

type Accounts struct {
	store  AccountStore
	claims auth.ClaimWriter
	logger *slog.Logger
}

func NewAccounts(store AccountStore, claims auth.ClaimWriter, logger *slog.Logger) *Accounts {
	return &Accounts{
		store:  store,
		claims: claims,
		logger: logger.With("service", "accounts"),
	}
}

type SetupProfileInput struct {
	FullName string
}

var (
	errAccountNotFound  = xerrors.NotFound.New("ACCOUNT_NOT_FOUND", "This account does not exist.")
	errEmailNotVerified = xerrors.Denied.New("EMAIL_NOT_VERIFIED", "Verify your email address before creating an account.")
	errPhoneRequired    = xerrors.Denied.New("PHONE_REQUIRED", "Verify a phone number before creating an account.")
)

func (s *Accounts) Get(ctx context.Context, id uuid.UUID) (database.Account, error) {
	account, err := s.store.GetAccountByID(ctx, id)
	if err != nil {
		if database.IsNoRows(err) {
			return database.Account{}, errAccountNotFound
		}
		return database.Account{}, err
	}
	return account, nil
}

func (s *Accounts) SetupProfile(ctx context.Context, principal auth.Principal, input SetupProfileInput) (database.Account, error) {
	s.logger.DebugContext(ctx, "setup account profile",
		slog.Any("principal", principal),
		slog.Any("input", input),
	)

	emailVerified := principal.BoolClaim("email_verified")
	phone := principal.Claim("phone_number")
	if !emailVerified {
		return database.Account{}, errEmailNotVerified
	}

	if phone == "" {
		return database.Account{}, errPhoneRequired
	}

	account, err := s.store.InsertAccount(ctx, database.InsertAccountParams{
		FullName:    input.FullName,
		FirebaseUID: principal.Subject,
		Email:       principal.Email,
		Avatar:      principal.Claim("picture"),
		Phone:       phone,
	})
	if err != nil {
		if database.IsUniqueViolation(err) {
			s.logger.ErrorContext(ctx, "account row outlived the identity holding its email or phone",
				slog.String("constraint", database.ConstraintName(err)),
			)
		}
		return database.Account{}, err
	}
	s.logger.InfoContext(ctx, "account profile setup completed", slog.String("account_id", account.ID.String()))

	if err := s.claims.SetAccountClaim(ctx, principal.Subject, account.ID.String()); err != nil {
		return database.Account{}, err
	}
	return account, nil
}
