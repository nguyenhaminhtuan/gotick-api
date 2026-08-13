package api

import (
	"context"

	"gotick/internal/oas"
)

// citiesHandler serves the Cities operations, across every audience that exposes them.
type citiesHandler struct{ deps }

// Compile-time check for citiesHandler.
var _ oas.CitiesHandler = (*citiesHandler)(nil)

// ActivateAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) ActivateAdminCity(ctx context.Context, params oas.ActivateAdminCityParams) (oas.ActivateAdminCityRes, error) {
	panic("unimplemented")
}

// CreateAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) CreateAdminCity(ctx context.Context) (oas.CreateAdminCityRes, error) {
	panic("unimplemented")
}

// DeactivateAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) DeactivateAdminCity(ctx context.Context, params oas.DeactivateAdminCityParams) (oas.DeactivateAdminCityRes, error) {
	panic("unimplemented")
}

// GetAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) GetAdminCity(ctx context.Context, params oas.GetAdminCityParams) (oas.GetAdminCityRes, error) {
	panic("unimplemented")
}

// ListAdminCities implements [oas.CitiesHandler].
func (h *citiesHandler) ListAdminCities(ctx context.Context) (oas.ListAdminCitiesRes, error) {
	panic("unimplemented")
}

// ListPublicCities implements [oas.CitiesHandler].
func (h *citiesHandler) ListPublicCities(ctx context.Context) (oas.ListPublicCitiesRes, error) {
	panic("unimplemented")
}

// UpdateAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) UpdateAdminCity(ctx context.Context, params oas.UpdateAdminCityParams) (oas.UpdateAdminCityRes, error) {
	panic("unimplemented")
}
