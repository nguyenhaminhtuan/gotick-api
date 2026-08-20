package api

import (
	"context"

	"gotick/internal/oas"
)

// eventsHandler serves the Events operations, across every audience that exposes them.
type eventsHandler struct{}

// Compile-time check for eventsHandler.
var _ oas.EventsHandler = (*eventsHandler)(nil)

// CloseOrgEvent implements [oas.EventsHandler].
func (h *eventsHandler) CloseOrgEvent(ctx context.Context, params oas.CloseOrgEventParams) (oas.CloseOrgEventRes, error) {
	panic("unimplemented")
}

// CreateOrgEvent implements [oas.EventsHandler].
func (h *eventsHandler) CreateOrgEvent(ctx context.Context, params oas.CreateOrgEventParams) (oas.CreateOrgEventRes, error) {
	panic("unimplemented")
}

// GetOrgEvent implements [oas.EventsHandler].
func (h *eventsHandler) GetOrgEvent(ctx context.Context, params oas.GetOrgEventParams) (oas.GetOrgEventRes, error) {
	panic("unimplemented")
}

// GetPublicEvent implements [oas.EventsHandler].
func (h *eventsHandler) GetPublicEvent(ctx context.Context, params oas.GetPublicEventParams) (oas.GetPublicEventRes, error) {
	panic("unimplemented")
}

// ListOrgEvents implements [oas.EventsHandler].
func (h *eventsHandler) ListOrgEvents(ctx context.Context, params oas.ListOrgEventsParams) (oas.ListOrgEventsRes, error) {
	panic("unimplemented")
}

// ListPublicEvents implements [oas.EventsHandler].
func (h *eventsHandler) ListPublicEvents(ctx context.Context, params oas.ListPublicEventsParams) (oas.ListPublicEventsRes, error) {
	panic("unimplemented")
}

// ListPublicFeaturedEvents implements [oas.EventsHandler].
func (h *eventsHandler) ListPublicFeaturedEvents(ctx context.Context, params oas.ListPublicFeaturedEventsParams) (oas.ListPublicFeaturedEventsRes, error) {
	panic("unimplemented")
}

// ListPublicRelatedEvents implements [oas.EventsHandler].
func (h *eventsHandler) ListPublicRelatedEvents(ctx context.Context, params oas.ListPublicRelatedEventsParams) (oas.ListPublicRelatedEventsRes, error) {
	panic("unimplemented")
}

// ListPublicUpcomingEvents implements [oas.EventsHandler].
func (h *eventsHandler) ListPublicUpcomingEvents(ctx context.Context, params oas.ListPublicUpcomingEventsParams) (oas.ListPublicUpcomingEventsRes, error) {
	panic("unimplemented")
}

// PublishOrgEvent implements [oas.EventsHandler].
func (h *eventsHandler) PublishOrgEvent(ctx context.Context, params oas.PublishOrgEventParams) (oas.PublishOrgEventRes, error) {
	panic("unimplemented")
}

// UpdateOrgEvent implements [oas.EventsHandler].
func (h *eventsHandler) UpdateOrgEvent(ctx context.Context, params oas.UpdateOrgEventParams) (oas.UpdateOrgEventRes, error) {
	panic("unimplemented")
}
