package api

import (
	"gotick/internal/oas"
)

func mapSlice[S ~[]R, T, R any](in []T, f func(*T) *R) S {
	out := make(S, len(in))
	for i := range in {
		out[i] = *f(&in[i])
	}
	return out
}

func toOptString(t *string) oas.OptString {
	if t == nil {
		return oas.OptString{}
	}
	return oas.NewOptString(*t)
}
