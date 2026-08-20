-- +goose NO TRANSACTION
-- +goose Up
SET lock_timeout = '5s';
SET statement_timeout = '30s';

ALTER TABLE "accounts"
ADD COLUMN IF NOT EXISTS "firebase_uid" text NOT NULL DEFAULT '';
ALTER TABLE "accounts" ALTER COLUMN "firebase_uid" DROP DEFAULT;

ALTER TABLE "accounts" ADD COLUMN IF NOT EXISTS "phone" text NOT NULL DEFAULT '';
ALTER TABLE "accounts" ALTER COLUMN "phone" DROP DEFAULT;
ALTER TABLE "accounts"
ADD COLUMN IF NOT EXISTS "phone_changed_at" timestamptz NOT NULL DEFAULT now();

-- squawk-ignore ban-concurrent-index-creation-in-transaction
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "accounts_firebase_uid_key"
ON "accounts" ("firebase_uid");

-- squawk-ignore ban-concurrent-index-creation-in-transaction
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "accounts_phone_key"
ON "accounts" ("phone");

-- +goose Down
