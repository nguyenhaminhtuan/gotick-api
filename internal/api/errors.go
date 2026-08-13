package api

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"gotick/internal/oas"

	"github.com/ogen-go/ogen/ogenerrors"
)

var (
	errUnauthorized         = oas.Error{Error: "Unauthorized", Message: "Authentication is required."}
	errValidation           = oas.Error{Error: "ValidationError", Message: "The request is invalid."}
	errNotFound             = oas.Error{Error: "NotFound", Message: "The requested resource does not exist."}
	errMethodNotAllowed     = oas.Error{Error: "MethodNotAllowed", Message: "The method is not allowed for this resource."}
	errUnsupportedMediaType = oas.Error{Error: "UnsupportedMediaType", Message: "Content-Type is not supported."}
	errInternal             = oas.Error{Error: "InternalServerError", Message: "An unexpected error occurred. Please try again later."}
)

type APIError struct {
	StatusCode int
	ErrorCode  string
	Message    string
	Err        error
}

func (e *APIError) Error() string { return e.Message }

func (e *APIError) Unwrap() error { return e.Err }

func NewAPIError(status int, code string, msg string) *APIError {
	return &APIError{
		StatusCode: status,
		ErrorCode:  code,
		Message:    msg,
	}
}

// NewError implements [oas.Handler].
func (h *Handler) NewError(ctx context.Context, err error) *oas.DefaultStatusCode {
	if apiErr, ok := errors.AsType[*APIError](err); ok {
		if apiErr.Err != nil {
			h.logger.WarnContext(ctx, "request rejected", slog.Any("err", apiErr.Err))
		}

		return &oas.DefaultStatusCode{
			StatusCode: apiErr.StatusCode,
			Response: oas.Error{
				Error:   apiErr.ErrorCode,
				Message: apiErr.Message,
			},
		}
	}

	if secErr, ok := errors.AsType[*ogenerrors.SecurityError](err); ok {
		h.logger.WarnContext(ctx, "authentication failed",
			slog.Any("err", secErr),
			slog.String("operation", secErr.OperationID()),
		)

		return &oas.DefaultStatusCode{
			StatusCode: http.StatusUnauthorized,
			Response:   errUnauthorized,
		}
	}

	h.logger.ErrorContext(ctx, "unhandled handler error", slog.Any("err", err))

	return &oas.DefaultStatusCode{
		StatusCode: http.StatusInternalServerError,
		Response:   errInternal,
	}
}

func (h *Handler) ErrorHandler(ctx context.Context, w http.ResponseWriter, r *http.Request, err error) {
	code := ogenerrors.ErrorCode(err)

	var resp oas.Error
	switch code {
	case http.StatusUnauthorized:
		resp = errUnauthorized
	case http.StatusBadRequest:
		resp = errValidation
	case http.StatusUnsupportedMediaType:
		resp = errUnsupportedMediaType
	default:
		resp = errInternal
	}

	h.logger.ErrorContext(ctx, "request failed before handler",
		slog.Any("err", err),
		slog.Int("status", code),
		slog.String("method", r.Method),
		slog.String("path", r.URL.Path),
	)

	writeJSONError(w, code, resp)
}

func (h *Handler) NotFound(w http.ResponseWriter, r *http.Request) {
	writeJSONError(w, http.StatusNotFound, errNotFound)
}

func (h *Handler) MethodNotAllowed(w http.ResponseWriter, r *http.Request, allowed string) {
	w.Header().Set("Allow", allowed)
	writeJSONError(w, http.StatusMethodNotAllowed, errMethodNotAllowed)
}

func writeJSONError(w http.ResponseWriter, code int, resp oas.Error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(resp)
}
