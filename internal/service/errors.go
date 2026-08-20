package service

import "errors"

type Kind int

const (
	KindInternal Kind = iota
	KindInvalid
	KindUnauthenticated
	KindDenied
	KindNotFound
	KindConflict
)

func (k Kind) New(code, msg string) *Error {
	return &Error{Kind: k, Code: code, Msg: msg}
}

var xerrors = struct {
	Internal        Kind
	Invalid         Kind
	Unauthenticated Kind
	Denied          Kind
	NotFound        Kind
	Conflict        Kind
}{
	Internal:        KindInternal,
	Invalid:         KindInvalid,
	Unauthenticated: KindUnauthenticated,
	Denied:          KindDenied,
	NotFound:        KindNotFound,
	Conflict:        KindConflict,
}

type Error struct {
	Kind  Kind
	Code  string
	Msg   string
	Cause error
}

func (e *Error) Error() string { return e.Msg }

func (e *Error) Wrap(err error) *Error {
	e.Cause = err
	return e
}

func KindOf(err error) Kind {
	svcErr, ok := errors.AsType[*Error](err)
	if !ok {
		return KindInternal
	}
	return svcErr.Kind
}
