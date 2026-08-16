package api

import (
	"context"

	"gotick/internal/database"
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
	cities, err := h.db.GetCities(ctx)
	if err != nil {
		return nil, err
	}
	res := mapSlice[oas.CityList](cities, toCity)
	return &res, nil
}

// ListPublicCities implements [oas.CitiesHandler].
func (h *citiesHandler) ListPublicCities(ctx context.Context) (oas.ListPublicCitiesRes, error) {
	cities, err := h.db.GetCities(ctx)
	if err != nil {
		return nil, err
	}
	res := mapSlice[oas.PublicCityList](cities, toPublicCity)
	return &res, nil
}

// UpdateAdminCity implements [oas.CitiesHandler].
func (h *citiesHandler) UpdateAdminCity(ctx context.Context, params oas.UpdateAdminCityParams) (oas.UpdateAdminCityRes, error) {
	panic("unimplemented")
}

func toCity(c *database.City) *oas.City {
	return &oas.City{
		Code:       c.Code,
		Name:       c.Name,
		NameEn:     toOptString(c.NameEn),
		FullName:   c.FullName,
		FullNameEn: toOptString(c.FullNameEn),
		Status:     oas.CityStatus(c.Status),
	}
}

func toPublicCity(c *database.City) *oas.PublicCity {
	return &oas.PublicCity{
		Code:       c.Code,
		Name:       c.Name,
		NameEn:     toOptString(c.NameEn),
		FullName:   c.FullName,
		FullNameEn: toOptString(c.FullNameEn),
	}
}
