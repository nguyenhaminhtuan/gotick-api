package api

import (
	"context"
	"gotick/internal/oas"
)

// ordersHandler serves the Orders operations, across every audience that exposes them.
type ordersHandler struct{ deps }

// Compile-time check for ordersHandler.
var _ oas.OrdersHandler = (*ordersHandler)(nil)

// CreateMyOrder implements [oas.OrdersHandler].
func (h *ordersHandler) CreateMyOrder(ctx context.Context) (oas.CreateMyOrderRes, error) {
	panic("unimplemented")
}

// GetMyOrder implements [oas.OrdersHandler].
func (h *ordersHandler) GetMyOrder(ctx context.Context, params oas.GetMyOrderParams) (oas.GetMyOrderRes, error) {
	panic("unimplemented")
}

// ListMyOrders implements [oas.OrdersHandler].
func (h *ordersHandler) ListMyOrders(ctx context.Context, params oas.ListMyOrdersParams) (oas.ListMyOrdersRes, error) {
	panic("unimplemented")
}
