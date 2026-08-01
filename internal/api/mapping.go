package api

import (
	"gotick/internal/oas"

	"github.com/jackc/pgx/v5/pgtype"
)

func mapSlice[S ~[]R, T, R any](in []T, f func(*T) *R) S {
	out := make(S, len(in))
	for i := range in {
		out[i] = *f(&in[i])
	}
	return out
}

func toOptString(t pgtype.Text) oas.OptString {
	if !t.Valid {
		return oas.OptString{}
	}
	return oas.NewOptString(t.String)
}
