package api

import (
	"context"

	"gotick/internal/oas"
)

// occurrencesHandler serves the Occurrences operations, across every audience that exposes them.
type occurrencesHandler struct{}

// Compile-time check for occurrencesHandler.
var _ oas.OccurrencesHandler = (*occurrencesHandler)(nil)

// CancelOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) CancelOrgOccurrence(ctx context.Context, params oas.CancelOrgOccurrenceParams) (oas.CancelOrgOccurrenceRes, error) {
	panic("unimplemented")
}

// CreateOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) CreateOrgOccurrence(ctx context.Context, params oas.CreateOrgOccurrenceParams) (oas.CreateOrgOccurrenceRes, error) {
	panic("unimplemented")
}

// GetOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) GetOrgOccurrence(ctx context.Context, params oas.GetOrgOccurrenceParams) (oas.GetOrgOccurrenceRes, error) {
	panic("unimplemented")
}

// ListOrgOccurrences implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) ListOrgOccurrences(ctx context.Context, params oas.ListOrgOccurrencesParams) (oas.ListOrgOccurrencesRes, error) {
	panic("unimplemented")
}

// ListPublicEventOccurrences implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) ListPublicEventOccurrences(ctx context.Context, params oas.ListPublicEventOccurrencesParams) (oas.ListPublicEventOccurrencesRes, error) {
	panic("unimplemented")
}

// PostponeOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) PostponeOrgOccurrence(ctx context.Context, params oas.PostponeOrgOccurrenceParams) (oas.PostponeOrgOccurrenceRes, error) {
	panic("unimplemented")
}

// RescheduleOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) RescheduleOrgOccurrence(ctx context.Context, params oas.RescheduleOrgOccurrenceParams) (oas.RescheduleOrgOccurrenceRes, error) {
	panic("unimplemented")
}

// UpdateOrgOccurrence implements [oas.OccurrencesHandler].
func (h *occurrencesHandler) UpdateOrgOccurrence(ctx context.Context, params oas.UpdateOrgOccurrenceParams) (oas.UpdateOrgOccurrenceRes, error) {
	panic("unimplemented")
}
