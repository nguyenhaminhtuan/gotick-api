ifneq (,$(wildcard .env))
	include .env
	export
endif

BUILD_DIR 	:= ./bin
API_ENTRY	:= ./cmd/api
DB_SCHEMA 	?= app
DB_PORT		?= 5432

export GOOSE_DRIVER          := postgres
export GOOSE_DBSTRING        := postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSL_MODE)&search_path=$(DB_SCHEMA)
export GOOSE_MIGRATION_DIR   ?= db/migrations
export GOOSE_TABLE           ?= public.migrations

##@ Build & Test
.PHONY: build
build: ## Build application
	@echo "Building..."
	@go build -o $(BUILD_DIR)/api $(API_ENTRY)

.PHONY: clean
clean: ## Cleanup build artifacts
	@echo "Cleaning up..."
	@rm -rf $(BUILD_DIR)

##@ Development
.PHONY: run
run: ## Run application
	@go run $(API_ENTRY)

.PHONY: watch
watch: ## Run application in watch mode
	@air

.PHONY: sqlc-generate
sqlc-generate: ## Generate code from SQL queries
	@sqlc generate

.PHONY: sql-lint
sql-lint: ## Lint and check formatting of SQL files
	@sqlfluff lint db

.PHONY: sql-format
sql-format: ## Format SQL files in place
	@sqlfluff format db

##@ Migrations
.PHONY: migrate-new
migrate-new: ## Create an empty migration file
	goose create $(name) sql

.PHONY: migrate-up
migrate-up: ## Apply migration to latest version
	goose up

.PHONY: migrate-down
migrate-down: ## Rollback a latest migration version
	goose down

.PHONY: migrate-status
migrate-status: ## Show migration status
	goose status

.PHONY: migrate-version
migrate-version: ## Show the current migration version
	goose version

.PHONY: migrate-lint
migrate-lint: ## Lint migration files
	find ./db/migrations ./db/background -name '*.sql' -exec squawk -c=.squawk.toml {} +

##@API Docs
.PHONY: openapi-bundle
openapi-bundle: ## Bundle OpenAPI specs
	redocly bundle

.PHONY: openapi-codegen
openapi-codegen: ## Generate code from OpenAPI specs
	go generate ./...

.PHONY: openapi-lint
openapi-lint: ## Lint OpenAPI specs
	redocly lint

##@ Misc
.PHONY: help
help: ## Show usage for this file
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)