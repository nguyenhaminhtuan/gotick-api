package api

func listResponse[S ~[]R, T, R any](in []T, f func(*T) *R) S {
	out := make(S, len(in))
	for i := range in {
		out[i] = *f(&in[i])
	}
	return out
}

type optional[T any] interface {
	Get() (T, bool)
}

func wrapOpt[T, O any](v *T, wrap func(T) O) O {
	if v == nil {
		var zero O
		return zero
	}

	return wrap(*v)
}

func unwrapOpt[T any, O optional[T]](v O) *T {
	value, ok := v.Get()
	if !ok {
		return nil
	}

	return &value
}
