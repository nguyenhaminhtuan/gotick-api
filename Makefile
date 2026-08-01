BUILD_DIR 	:= ./bin
API_ENTRY	:= ./cmd/api
MIGRATE_CMD := go run ./cmd/migrate

ifneq (,$(wildcard .env))
	include .env
	export
endif

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

##@ Migrations
.PHONY: migrate-new
migrate-new: ## Create a new migration file
	dbmate -d db/migrations new $(name)

.PHONY: migrate-up
migrate-up: ## Apply migration to latest version
	$(MIGRATE_CMD) up

.PHONY: migrate-down
migrate-down: ## Rollback a latest migration version
	$(MIGRATE_CMD) down

.PHONY: migrate-status
migrate-status: ## Show migration status
	$(MIGRATE_CMD) status

.PHONY: migrate-lint
migrate-lint: ## Lint migration files
	squawk -c=.squawk.toml ./db/migrations/*.sql

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