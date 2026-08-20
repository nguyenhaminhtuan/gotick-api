package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"os"

	"gotick/internal/auth"
	"gotick/internal/config"
	"gotick/internal/database"
	"gotick/internal/log"
)

func main() {
	err := run(context.Background())
	switch {
	case err == nil:
	case errors.Is(err, flag.ErrHelp):
		// The usage text has already been printed, and asking for it is not a
		// failed run.
	default:
		slog.Error("failed to grant staff", slog.Any("error", err))
		os.Exit(1)
	}
}

type options struct {
	subject  string
	role     string
	fullName string
	phone    string
}

func parseOptions(args []string) (options, error) {
	var opts options

	fs := flag.NewFlagSet("grant-staff", flag.ContinueOnError)
	fs.StringVar(&opts.subject, "uid", "", "identity provider UID to grant staff to (required)")
	fs.StringVar(&opts.role, "role", auth.StaffRoleStaff, "role to grant: owner or staff")
	fs.StringVar(&opts.fullName, "name", "", "full name, only read when the account does not exist yet")
	fs.StringVar(&opts.phone, "phone", "", "phone number, only read when the account does not exist yet")
	if err := fs.Parse(args); err != nil {
		return options{}, err
	}

	if opts.subject == "" {
		return options{}, errors.New("-uid is required")
	}
	if opts.role != auth.StaffRoleOwner && opts.role != auth.StaffRoleStaff {
		return options{}, fmt.Errorf("-role must be %q or %q, got %q", auth.StaffRoleOwner, auth.StaffRoleStaff, opts.role)
	}
	return opts, nil
}

func run(ctx context.Context) error {
	opts, err := parseOptions(os.Args[1:])
	if err != nil {
		return err
	}

	cfg, err := config.Load()
	if err != nil {
		return err
	}

	logger, err := log.New(cfg.LogConfig)
	if err != nil {
		return err
	}
	logger = logger.With(slog.String("uid", opts.subject), slog.String("role", opts.role))

	pool, err := database.NewPostgresPool(ctx, cfg.DBConfig, logger)
	if err != nil {
		return err
	}
	db := database.NewDB(pool)
	defer db.Close()

	provider, err := auth.NewFirebaseVerifier(ctx)
	if err != nil {
		return err
	}

	return grant(ctx, db, provider, logger, opts)
}

func grant(ctx context.Context, db database.Store, provider auth.Provider, logger *slog.Logger, opts options) error {
	// Read the identity first: a wrong UID is the likeliest mistake, and this
	// is the last point where nothing has been written yet.
	user, err := provider.GetUser(ctx, opts.subject)
	if err != nil {
		return err
	}

	account, err := loadOrCreateAccount(ctx, db, logger, user, opts)
	if err != nil {
		return err
	}

	if _, err := db.UpsertPlatformStaff(ctx, database.UpsertPlatformStaffParams{
		AccountID: account.ID,
		Role:      opts.role,
		// Nobody on the platform granted this. Recording an account here would
		// name whoever the operator happened to be, which is not the same thing.
		GrantedBy: nil,
	}); err != nil {
		return fmt.Errorf("upsert platform staff: %w", err)
	}

	// Last, because these are the only writes that leave the database and the
	// only ones a retry cannot infer. Everything before them is already
	// durable. The account claim is stamped too: an account this command had
	// to create has never been through registration, which is what normally
	// writes it.
	if err := provider.SetAccountClaim(ctx, opts.subject, account.ID.String()); err != nil {
		return err
	}
	if err := provider.SetStaffClaim(ctx, opts.subject, opts.role); err != nil {
		return err
	}

	logger.InfoContext(ctx, "staff granted",
		slog.String("account_id", account.ID.String()),
		slog.String("email", account.Email),
	)
	logger.InfoContext(ctx, "the identity must refresh its token before the new role takes effect")
	return nil
}

func loadOrCreateAccount(
	ctx context.Context,
	db database.Store,
	logger *slog.Logger,
	user auth.User,
	opts options,
) (database.Account, error) {
	account, err := db.GetAccountByFirebaseUID(ctx, opts.subject)
	if err == nil {
		logger.InfoContext(ctx, "account already exists", slog.String("account_id", account.ID.String()))
		return account, nil
	}
	if !database.IsNoRows(err) {
		return database.Account{}, fmt.Errorf("get account: %w", err)
	}

	// The flags win over the provider record, which often carries neither for
	// an identity created by hand in a console.
	fullName := firstNonEmpty(opts.fullName, user.FullName)
	phone := firstNonEmpty(opts.phone, user.Phone)

	switch {
	case user.Email == "":
		return database.Account{}, errors.New("the identity has no email address, which an account requires")
	case fullName == "":
		return database.Account{}, errors.New("no account yet and the identity has no display name: pass -name")
	case phone == "":
		// Leaving it empty would take the one empty-phone slot the unique index
		// allows, so it has to be said out loud rather than defaulted.
		return database.Account{}, errors.New("no account yet and the identity has no phone number: pass -phone")
	}

	account, err = db.InsertAccount(ctx, database.InsertAccountParams{
		FirebaseUID: opts.subject,
		FullName:    fullName,
		Email:       user.Email,
		Avatar:      user.Avatar,
		Phone:       phone,
	})
	if err != nil {
		return database.Account{}, fmt.Errorf("insert account: %w", err)
	}

	logger.InfoContext(ctx, "account created", slog.String("account_id", account.ID.String()))
	return account, nil
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
