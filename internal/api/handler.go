package api

import (
	"log/slog"

	"gotick/internal/auth"
	"gotick/internal/database"
	"gotick/internal/oas"
)

type deps struct {
	db       *database.DB
	logger   *slog.Logger
	verifier auth.Verifier
}

type Handler struct {
	deps

	categoriesHandler
	citiesHandler
	eventsHandler
	occurrencesHandler
	ordersHandler
	organizerApplicationsHandler
	organizersHandler
	profileHandler
	salePhasesHandler
	ticketCategoriesHandler
	ticketsHandler
}

// Compile-time check for Handler.
var _ oas.Handler = (*Handler)(nil)

func NewHandler(db *database.DB, logger *slog.Logger, verifier auth.Verifier) *Handler {
	d := deps{
		db:       db,
		logger:   logger.With("component", "api"),
		verifier: verifier,
	}

	return &Handler{
		deps:                         d,
		categoriesHandler:            categoriesHandler{deps: d},
		citiesHandler:                citiesHandler{deps: d},
		eventsHandler:                eventsHandler{deps: d},
		occurrencesHandler:           occurrencesHandler{deps: d},
		ordersHandler:                ordersHandler{deps: d},
		organizerApplicationsHandler: organizerApplicationsHandler{deps: d},
		organizersHandler:            organizersHandler{deps: d},
		profileHandler:               profileHandler{deps: d},
		salePhasesHandler:            salePhasesHandler{deps: d},
		ticketCategoriesHandler:      ticketCategoriesHandler{deps: d},
		ticketsHandler:               ticketsHandler{deps: d},
	}
}
