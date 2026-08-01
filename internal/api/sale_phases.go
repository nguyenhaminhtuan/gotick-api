package api

import (
	"context"
	"gotick/internal/oas"
)

// salePhasesHandler serves the SalePhases operations, across every audience that exposes them.
type salePhasesHandler struct{ deps }

// Compile-time check for salePhasesHandler.
var _ oas.SalePhasesHandler = (*salePhasesHandler)(nil)

// CancelOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) CancelOrgSalePhase(ctx context.Context, params oas.CancelOrgSalePhaseParams) (oas.CancelOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// CreateOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) CreateOrgSalePhase(ctx context.Context, params oas.CreateOrgSalePhaseParams) (oas.CreateOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// EndOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) EndOrgSalePhase(ctx context.Context, params oas.EndOrgSalePhaseParams) (oas.EndOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// GetOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) GetOrgSalePhase(ctx context.Context, params oas.GetOrgSalePhaseParams) (oas.GetOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// ListOrgSalePhases implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) ListOrgSalePhases(ctx context.Context, params oas.ListOrgSalePhasesParams) (oas.ListOrgSalePhasesRes, error) {
	panic("unimplemented")
}

// ListPublicSalePhases implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) ListPublicSalePhases(ctx context.Context, params oas.ListPublicSalePhasesParams) (oas.ListPublicSalePhasesRes, error) {
	panic("unimplemented")
}

// StartOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) StartOrgSalePhase(ctx context.Context, params oas.StartOrgSalePhaseParams) (oas.StartOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// SuspendOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) SuspendOrgSalePhase(ctx context.Context, params oas.SuspendOrgSalePhaseParams) (oas.SuspendOrgSalePhaseRes, error) {
	panic("unimplemented")
}

// UpdateOrgSalePhase implements [oas.SalePhasesHandler].
func (h *salePhasesHandler) UpdateOrgSalePhase(ctx context.Context, params oas.UpdateOrgSalePhaseParams) (oas.UpdateOrgSalePhaseRes, error) {
	panic("unimplemented")
}
