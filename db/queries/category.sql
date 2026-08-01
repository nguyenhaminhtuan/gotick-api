-- name: GetCategories :many
SELECT *
FROM categories
WHERE status = 'active'
ORDER BY display_order;

-- name: InsertCategory :execrows
INSERT INTO categories (name, slug, icon, display_order)
VALUES ($1, $2, $3, $4);