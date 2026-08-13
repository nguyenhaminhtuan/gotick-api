package api

import (
	"context"

	"gotick/internal/oas"
)

// ticketsHandler serves the Tickets operations, across every audience that exposes them.
type ticketsHandler struct{ deps }

// Compile-time check for ticketsHandler.
var _ oas.TicketsHandler = (*ticketsHandler)(nil)

// GetMyTicket implements [oas.TicketsHandler].
func (h *ticketsHandler) GetMyTicket(ctx context.Context, params oas.GetMyTicketParams) (oas.GetMyTicketRes, error) {
	panic("unimplemented")
}

// ListMyTickets implements [oas.TicketsHandler].
func (h *ticketsHandler) ListMyTickets(ctx context.Context, params oas.ListMyTicketsParams) (oas.ListMyTicketsRes, error) {
	panic("unimplemented")
}
