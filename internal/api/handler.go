package api

import (
	"log/slog"

	"gotick/internal/auth"
	"gotick/internal/oas"
	"gotick/internal/service"
)

type Handler struct {
	logger   *slog.Logger
	verifier auth.Verifier

	categoriesHandler
	citiesHandler
	eventsHandler
	membersHandler
	occurrencesHandler
	ordersHandler
	organizerApplicationsHandler
	organizersHandler
	profileHandler
	salePhasesHandler
	staffHandler
	ticketCategoriesHandler
	ticketsHandler
}

// Compile-time check for Handler.
var _ oas.Handler = (*Handler)(nil)

func NewHandler(
	categories *service.Categories,
	accounts *service.Accounts,
	staff *service.Staff,
	logger *slog.Logger,
	verifier auth.Verifier,
) *Handler {
	return &Handler{
		logger:   logger.With("component", "api"),
		verifier: verifier,

		categoriesHandler: categoriesHandler{categories: categories},
		profileHandler:    profileHandler{accounts: accounts},
		staffHandler:      staffHandler{staff: staff},
	}
}
