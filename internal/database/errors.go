package database

import (
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// PostgreSQL error codes.
// https://www.postgresql.org/docs/current/errcodes-appendix.html
const (
	codeUniqueViolation = "23505"
	codeQueryCanceled   = "57014"
)

// IsNoRows reports whether err means the query matched no row.
func IsNoRows(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}

// IsUniqueViolation reports whether err is a unique constraint violation.
func IsUniqueViolation(err error) bool {
	pgErr, ok := errors.AsType[*pgconn.PgError](err)
	return ok && pgErr.Code == codeUniqueViolation
}

func ConstraintName(err error) string {
	pgErr, ok := errors.AsType[*pgconn.PgError](err)
	if !ok {
		return ""
	}
	return pgErr.ConstraintName
}

// IsQueryCanceled reports whether the server cut the query short, which is what
// statement_timeout does.
func IsQueryCanceled(err error) bool {
	pgErr, ok := errors.AsType[*pgconn.PgError](err)
	return ok && pgErr.Code == codeQueryCanceled
}
