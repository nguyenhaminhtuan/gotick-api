-- name: GetCities :many
SELECT *
FROM cities
WHERE status = 'active';