#!/bin/sh

set -eu

export GOOSE_DRIVER=postgres
export GOOSE_DBSTRING="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT:-5432}/${DB_NAME}?sslmode=${DB_SSL_MODE:-require}&search_path=${DB_SCHEMA:-app}"

[ -n "$(ls -A "$GOOSE_MIGRATION_DIR"/*.sql 2>/dev/null)" ] || exit 0

exec goose "$@"
