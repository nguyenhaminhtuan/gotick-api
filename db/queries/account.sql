-- name: GetAccountByFirebaseUID :one
SELECT *
FROM accounts
WHERE firebase_uid = @firebase_uid::text;

-- name: InsertAccount :one
-- A repeat is the same identity finishing a setup that was interrupted, so the
-- row it already holds is the answer. DO NOTHING would return no row at all,
-- hence a write that changes nothing.
INSERT INTO accounts (firebase_uid, full_name, email, avatar, phone)
VALUES (@firebase_uid, @full_name, @email, @avatar, @phone)
ON CONFLICT (firebase_uid) DO UPDATE
    SET updated_at = accounts.updated_at
RETURNING *;

-- name: GetAccountByID :one
SELECT *
FROM accounts
WHERE id = @id;
