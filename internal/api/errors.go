package api

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"gotick/internal/database"
	"gotick/internal/oas"
	"gotick/internal/service"

	"github.com/ogen-go/ogen/ogenerrors"
)

const statusClientClosedRequest = 499

const codeInternal = "INTERNAL"

type status int

const (
	unauthorized status = http.StatusUnauthorized
	forbidden    status = http.StatusForbidden
	serverError  status = http.StatusInternalServerError
)

func (s status) New(code, msg string) *apiError {
	return &apiError{status: s, code: code, msg: msg}
}

type apiError struct {
	status status
	code   string
	msg    string
}

func (e *apiError) Error() string { return e.msg }

func httpStatus(kind service.Kind) status {
	switch kind {
	case service.KindInvalid:
		return http.StatusBadRequest
	case service.KindUnauthenticated:
		return http.StatusUnauthorized
	case service.KindDenied:
		return http.StatusForbidden
	case service.KindNotFound:
		return http.StatusNotFound
	case service.KindConflict:
		return http.StatusConflict
	case service.KindInternal:
		return http.StatusInternalServerError
	default:
		return http.StatusInternalServerError
	}
}

func (h *Handler) NewError(ctx context.Context, err error) *oas.DefaultStatusCode {
	switch {
	case errors.Is(err, context.Canceled):
		h.logger.DebugContext(ctx, "request canceled by caller")
		return &oas.DefaultStatusCode{
			StatusCode: statusClientClosedRequest,
			Response:   errorResponse("CANCELED", "The request was canceled."),
		}
	case errors.Is(err, context.DeadlineExceeded), database.IsQueryCanceled(err):
		h.logger.ErrorContext(ctx, "request timed out", slog.Any("err", err))
		return &oas.DefaultStatusCode{
			StatusCode: http.StatusGatewayTimeout,
			Response:   errorResponse("TIMEOUT", "The request took too long."),
		}
	}

	apiErr, owned := errors.AsType[*apiError](err)
	svcErr, classified := errors.AsType[*service.Error](err)
	_, security := errors.AsType[*ogenerrors.SecurityError](err)
	switch {
	case owned:
		h.logger.WarnContext(ctx, "request rejected", slog.String("code", apiErr.code))
	case classified:
		h.logger.WarnContext(ctx, "request rejected",
			slog.String("code", svcErr.Code),
			slog.Any("err", svcErr.Cause),
		)
		// The service says which kind of failure it was and this layer says
		// what that is worth over HTTP.
		apiErr = httpStatus(svcErr.Kind).New(svcErr.Code, svcErr.Msg)
	case security:
		h.logger.WarnContext(ctx, "request rejected", slog.Any("err", err))
		apiErr = errUnauthenticated
	default:
		h.logger.ErrorContext(ctx, "unhandled handler error", slog.Any("err", err))
		apiErr = serverError.New(codeInternal, "An unexpected error occurred. Please try again later.")
	}

	return &oas.DefaultStatusCode{
		StatusCode: int(apiErr.status),
		Response:   errorResponse(apiErr.code, apiErr.msg),
	}
}

// ErrorHandler answers the failures that happen before a handler runs: a body
// that will not decode, an unsupported media type, an operation with no
// implementation. They carry their own status, so this only has to name them.
func (h *Handler) ErrorHandler(ctx context.Context, w http.ResponseWriter, r *http.Request, err error) {
	code := ogenerrors.ErrorCode(err)

	var resp oas.Error
	switch code {
	case http.StatusUnauthorized:
		resp = errorResponse("UNAUTHENTICATED", "Authentication is required.")
	case http.StatusBadRequest:
		resp = errorResponse("INVALID_REQUEST", "The request is invalid.")
	case http.StatusUnsupportedMediaType:
		resp = errorResponse("UNSUPPORTED_MEDIA_TYPE", "Content-Type is not supported.")
	default:
		resp = errorResponse(codeInternal, "An unexpected error occurred. Please try again later.")
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
	writeJSONError(w, http.StatusNotFound, errorResponse("RESOURCE_NOT_FOUND", "The requested resource does not exist."))
}

func (h *Handler) MethodNotAllowed(w http.ResponseWriter, r *http.Request, allowed string) {
	w.Header().Set("Allow", allowed)
	writeJSONError(w, http.StatusMethodNotAllowed, errorResponse("METHOD_NOT_ALLOWED", "The method is not allowed for this resource."))
}

func errorResponse(code, msg string) oas.Error {
	return oas.Error{Error: code, Message: msg}
}

func writeJSONError(w http.ResponseWriter, code int, resp oas.Error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(resp)
}
