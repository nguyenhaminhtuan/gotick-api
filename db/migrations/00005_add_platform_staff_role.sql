-- +goose Up
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

ALTER TABLE "platform_staff"
ADD COLUMN IF NOT EXISTS "role" text NOT NULL DEFAULT 'staff';

ALTER TABLE "platform_staff"
ADD CONSTRAINT "platform_staff_role_check" CHECK (role IN ('owner', 'staff')) NOT VALID;

ALTER TABLE "platform_staff" ADD COLUMN IF NOT EXISTS "granted_by" uuid;

ALTER TABLE "platform_staff"
ADD CONSTRAINT "platform_staff_granted_by_fkey" FOREIGN KEY (
    "granted_by"
) REFERENCES "accounts" ("id") ON DELETE SET NULL NOT VALID;

-- +goose Down
