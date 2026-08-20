-- name: GetCategories :many
SELECT *
FROM categories
WHERE status = 'active'
ORDER BY display_order;

-- name: GetAllCategories :many
SELECT *
FROM categories
ORDER BY display_order;

-- name: GetCategory :one
SELECT *
FROM categories
WHERE id = @id;

-- name: InsertCategory :one
INSERT INTO categories (name, slug, icon, display_order)
VALUES (@name, @slug, @icon, @display_order)
RETURNING *;

-- name: UpdateCategory :one
UPDATE categories
SET
    name = @name,
    slug = @slug,
    icon = @icon,
    display_order = @display_order,
    updated_at = now()
WHERE id = @id
RETURNING *;

-- name: ActivateCategory :one
UPDATE categories
SET
    status = 'active',
    updated_at = now()
WHERE id = @id AND status = 'inactive'
RETURNING *;

-- name: DeactivateCategory :one
UPDATE categories
SET
    status = 'inactive',
    updated_at = now()
WHERE id = @id AND status = 'active'
RETURNING *;
