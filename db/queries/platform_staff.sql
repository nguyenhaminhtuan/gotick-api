-- name: GetPlatformStaffByAccountID :one
SELECT *
FROM platform_staff
WHERE account_id = @account_id;

-- name: ListPlatformStaff :many
SELECT
    s.*,
    a.firebase_uid,
    a.full_name,
    a.email,
    a.avatar
FROM platform_staff AS s
INNER JOIN accounts AS a ON s.account_id = a.id
ORDER BY s.created_at;

-- name: UpsertPlatformStaff :one
INSERT INTO platform_staff (account_id, role, granted_by)
VALUES (@account_id, @role, sqlc.narg('granted_by'))
ON CONFLICT (account_id) DO UPDATE
    SET
        role = excluded.role,
        updated_at = now()
RETURNING *;
