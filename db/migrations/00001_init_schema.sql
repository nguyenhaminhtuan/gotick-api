-- +goose Up
CREATE TABLE IF NOT EXISTS "accounts" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "full_name" text NOT NULL,
    "email" text NOT NULL,
    "avatar" text NOT NULL,
    "status" text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
    "suspended_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("email")
);

CREATE TABLE IF NOT EXISTS "organizers" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "name" text NOT NULL,
    "description" text NOT NULL,
    "organizer_type" text NOT NULL CHECK (organizer_type IN ('individual', 'organization')),
    "logo" text NOT NULL,
    "email" text NOT NULL,
    "phone" text NOT NULL,
    "public_contact" jsonb NOT NULL DEFAULT '{}',
    "status" text NOT NULL DEFAULT 'pending_registration' CHECK (status IN ('pending_registration', 'active', 'suspended')),
    "activated_at" timestamptz,
    "suspended_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("email")
);

CREATE TABLE IF NOT EXISTS "organizer_applications" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "organizer_id" uuid NOT NULL,
    "status" text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'changes_requested', 'rejected')),
    "review_note" text NOT NULL DEFAULT '',
    "reviewed_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("organizer_id") REFERENCES "organizers" ("id") ON DELETE CASCADE
);

CREATE INDEX "organizer_applications_organizer_id_idx" ON "organizer_applications" ("organizer_id");

CREATE TABLE IF NOT EXISTS "organizer_members" (
    "organizer_id" uuid NOT NULL,
    "account_id" uuid NOT NULL,
    "role" text NOT NULL CHECK (role IN ('owner', 'staff')),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("organizer_id", "account_id"),
    FOREIGN KEY ("organizer_id") REFERENCES "organizers" ("id") ON DELETE CASCADE,
    FOREIGN KEY ("account_id") REFERENCES "accounts" ("id") ON DELETE CASCADE
);

CREATE INDEX "organizer_members_account_id_idx" ON "organizer_members" ("account_id");

CREATE TABLE IF NOT EXISTS "platform_staff" (
    "account_id" uuid NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("account_id"),
    FOREIGN KEY ("account_id") REFERENCES "accounts" ("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "categories" (
    "id" smallint GENERATED ALWAYS AS IDENTITY,
    "name" text NOT NULL,
    "slug" varchar(60) NOT NULL,
    "icon" text,
    "display_order" smallint NOT NULL DEFAULT 0,
    "status" text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("slug")
);

CREATE TABLE IF NOT EXISTS "cities" (
    "code" varchar(20) NOT NULL,
    "name" text NOT NULL,
    "name_en" text,
    "full_name" text NOT NULL,
    "full_name_en" text,
    "status" text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    PRIMARY KEY ("code")
);

CREATE TABLE IF NOT EXISTS "events" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "organizer_id" uuid NOT NULL,
    "category_id" smallint,
    "name" text NOT NULL,
    "slug" varchar(60) NOT NULL,
    "description" text NOT NULL,
    "image" text NOT NULL,
    "status" text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'closed')),
    "is_listed" boolean NOT NULL DEFAULT true,
    "is_featured" boolean NOT NULL DEFAULT false,
    "published_at" timestamptz,
    "closed_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("slug"),
    FOREIGN KEY ("organizer_id") REFERENCES "organizers" ("id") ON DELETE CASCADE,
    FOREIGN KEY ("category_id") REFERENCES "categories" ("id") ON DELETE SET NULL
);

CREATE INDEX "events_organizer_id_idx" ON "events" ("organizer_id");

CREATE INDEX "events_category_id_idx" ON "events" ("category_id");

CREATE TABLE IF NOT EXISTS "occurrences" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "event_id" uuid NOT NULL,
    "name" text NOT NULL,
    "start_time" timestamptz NOT NULL,
    "end_time" timestamptz NOT NULL,
    "venue_name" text NOT NULL,
    "venue_address" text NOT NULL,
    "venue_city_code" varchar(20) NULL,
    "status" text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'canceled', 'postponed')),
    "waiting_room_enabled" boolean NOT NULL DEFAULT false,
    "canceled_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("event_id") REFERENCES "events" ("id") ON DELETE CASCADE,
    FOREIGN KEY ("venue_city_code") REFERENCES "cities" ("code") ON DELETE SET NULL
);

CREATE INDEX "occurrences_event_id_idx" ON "occurrences" ("event_id");

CREATE TABLE IF NOT EXISTS "ticket_categories" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "occurrence_id" uuid NOT NULL,
    "name" text NOT NULL,
    "zone" text NOT NULL DEFAULT '',
    "price" bigint NOT NULL,
    "quantity" int NOT NULL,
    "priority" int NOT NULL,
    "metadata" jsonb NOT NULL DEFAULT '{}',
    "max_buy_per_customer" int NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("occurrence_id") REFERENCES "occurrences" ("id") ON DELETE CASCADE
);

CREATE INDEX "ticket_categories_occurrence_id_idx" ON "ticket_categories" ("occurrence_id");

CREATE TABLE IF NOT EXISTS "sale_phases" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "occurrence_id" uuid NOT NULL,
    "name" text NOT NULL,
    "start_time" timestamptz NOT NULL,
    "end_time" timestamptz NOT NULL,
    "max_buy_per_customer" int NOT NULL,
    "status" text NOT NULL DEFAULT 'coming_soon' CHECK (status IN ('coming_soon', 'on_sale', 'suspended', 'ended', 'canceled')),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("occurrence_id") REFERENCES "occurrences" ("id") ON DELETE CASCADE
);

CREATE INDEX "sale_phases_occurrence_id_idx" ON "sale_phases" ("occurrence_id");

CREATE TABLE IF NOT EXISTS "sale_phase_categories" (
    "sale_phase_id" uuid NOT NULL,
    "ticket_category_id" uuid NOT NULL,
    PRIMARY KEY ("sale_phase_id", "ticket_category_id"),
    FOREIGN KEY ("sale_phase_id") REFERENCES "sale_phases" ("id") ON DELETE CASCADE,
    FOREIGN KEY ("ticket_category_id") REFERENCES "ticket_categories" ("id") ON DELETE CASCADE
);

CREATE INDEX "sale_phase_categories_ticket_category_id_idx" ON "sale_phase_categories" ("ticket_category_id");

CREATE TABLE IF NOT EXISTS "orders" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "customer_id" uuid NOT NULL,
    "occurrence_id" uuid NOT NULL,
    "total_amount" bigint NOT NULL CHECK (total_amount > 0),
    "status" text NOT NULL DEFAULT 'pending_payment' CHECK (status IN ('pending_payment', 'paid', 'canceled', 'expired')),
    "hold_expires_at" timestamptz,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("customer_id") REFERENCES "accounts" ("id"),
    FOREIGN KEY ("occurrence_id") REFERENCES "occurrences" ("id")
);

CREATE INDEX "orders_customer_id_idx" ON "orders" ("customer_id");

CREATE INDEX "orders_occurrence_id_idx" ON "orders" ("occurrence_id");

CREATE TABLE IF NOT EXISTS "order_items" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "order_id" uuid NOT NULL,
    "ticket_category_id" uuid NOT NULL,
    "quantity" int NOT NULL CHECK (quantity > 0),
    "unit_price" bigint NOT NULL CHECK (unit_price >= 0),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("order_id") REFERENCES "orders" ("id") ON DELETE CASCADE,
    FOREIGN KEY ("ticket_category_id") REFERENCES "ticket_categories" ("id") ON DELETE RESTRICT
);

CREATE INDEX "order_items_order_id_idx" ON "order_items" ("order_id");

CREATE INDEX "order_items_ticket_category_id_idx" ON "order_items" ("ticket_category_id");

CREATE TABLE IF NOT EXISTS "tickets" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "order_item_id" uuid NOT NULL,
    "event_id" uuid NOT NULL,
    "occurrence_id" uuid NOT NULL,
    "ticket_category_id" uuid NOT NULL,
    "qr_code" text NOT NULL,
    "status" text NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved', 'valid', 'checked_in', 'voided', 'refunded')),
    "issued_at" timestamptz NOT NULL DEFAULT now(),
    "used_at" timestamptz,
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("qr_code"),
    FOREIGN KEY ("order_item_id") REFERENCES "order_items" ("id"),
    FOREIGN KEY ("event_id") REFERENCES "events" ("id"),
    FOREIGN KEY ("occurrence_id") REFERENCES "occurrences" ("id"),
    FOREIGN KEY ("ticket_category_id") REFERENCES "ticket_categories" ("id")
);

CREATE INDEX "tickets_order_item_id_idx" ON "tickets" ("order_item_id");

CREATE TABLE IF NOT EXISTS "assets" (
    "id" uuid NOT NULL DEFAULT uuidv7(),
    "storage_key" text NOT NULL UNIQUE,
    "status" text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'committed')),
    "content_type" text NOT NULL,
    "size_bytes" bigint,
    "checksum" text,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "committed_at" timestamptz,
    PRIMARY KEY ("id")
);

-- +goose Down
