# Hanzo Stack Makefile
SHELL := /bin/bash

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# Docker compose command
COMPOSE := docker compose
COMPOSE_FILES := -f docker-compose.yml

# Service groups
CORE_SERVICES := postgres redis minio mongodb meilisearch clickhouse
AI_SERVICES := llm-gateway chat mcp agent operative
APP_SERVICES := search flow studio suite api cloud iam kms
BUSINESS_SERVICES := financials captable team
CUSTOMER_SERVICES := az2-admin az2-api

ALL_SERVICES := $(CORE_SERVICES) $(AI_SERVICES) $(APP_SERVICES) $(BUSINESS_SERVICES) $(CUSTOMER_SERVICES)

.PHONY: help
help:
	@echo "$(GREEN)Hanzo Stack Commands:$(NC)"
	@echo "  $(YELLOW)make clone-all$(NC)      - Clone all Hanzo repositories"
	@echo "  $(YELLOW)make up$(NC)             - Start all services"
	@echo "  $(YELLOW)make down$(NC)           - Stop all services"
	@echo "  $(YELLOW)make restart$(NC)        - Restart all services"
	@echo "  $(YELLOW)make logs$(NC)           - View all logs"
	@echo "  $(YELLOW)make health$(NC)         - Check service health"
	@echo ""
	@echo "$(GREEN)Service Groups:$(NC)"
	@echo "  $(YELLOW)make up-core$(NC)        - Start core infrastructure"
	@echo "  $(YELLOW)make up-ai$(NC)          - Start AI services"
	@echo "  $(YELLOW)make up-apps$(NC)        - Start application services"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  $(YELLOW)make dev$(NC)            - Start in development mode"
	@echo "  $(YELLOW)make test$(NC)           - Run all tests"
	@echo "  $(YELLOW)make build$(NC)          - Build all services"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  $(YELLOW)make clean$(NC)          - Clean containers and volumes"
	@echo "  $(YELLOW)make reset$(NC)          - Full reset (WARNING: deletes data)"
	@echo "  $(YELLOW)make backup$(NC)         - Backup all data"
	@echo "  $(YELLOW)make check-ports$(NC)    - Check for port conflicts"

# Clone all repositories
.PHONY: clone-all
clone-all:
	@echo "$(GREEN)Cloning all Hanzo repositories...$(NC)"
	@mkdir -p repos
	@cd repos && \
	for repo in llm chat mcp agent operative search flow studio suite api cloud iam kms financials captable team az2; do \
		if [ ! -d "$$repo" ]; then \
			echo "$(YELLOW)Cloning $$repo...$(NC)"; \
			git clone https://github.com/hanzoai/$$repo.git || echo "$(RED)Failed to clone $$repo$(NC)"; \
		else \
			echo "$(YELLOW)$$repo already exists, pulling latest...$(NC)"; \
			cd $$repo && git pull && cd ..; \
		fi; \
	done
	@echo "$(GREEN)All repositories cloned!$(NC)"

# Start all services
.PHONY: up
up: check-env
	@echo "$(GREEN)Starting Hanzo Stack...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) up -d
	@echo "$(GREEN)Hanzo Stack started!$(NC)"
	@echo "$(YELLOW)Run 'make health' to check service status$(NC)"

# Start core services only
.PHONY: up-core
up-core: check-env
	@echo "$(GREEN)Starting core infrastructure...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) up -d $(CORE_SERVICES)

# Start AI services only
.PHONY: up-ai
up-ai: check-env up-core
	@echo "$(GREEN)Starting AI services...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) up -d $(AI_SERVICES)

# Start application services
.PHONY: up-apps
up-apps: check-env up-core
	@echo "$(GREEN)Starting application services...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) up -d $(APP_SERVICES)

# Stop all services
.PHONY: down
down:
	@echo "$(YELLOW)Stopping Hanzo Stack...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) down
	@echo "$(GREEN)Hanzo Stack stopped!$(NC)"

# Restart all services
.PHONY: restart
restart: down up

# View logs
.PHONY: logs
logs:
	@$(COMPOSE) $(COMPOSE_FILES) logs -f $(service)

# Check service health
.PHONY: health
health:
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)Core Infrastructure:$(NC)"
	@for service in $(CORE_SERVICES); do \
		if $(COMPOSE) $(COMPOSE_FILES) ps $$service | grep -q "Up"; then \
			echo "  ✓ $$service"; \
		else \
			echo "  ✗ $$service"; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW)AI Services:$(NC)"
	@for service in $(AI_SERVICES); do \
		if $(COMPOSE) $(COMPOSE_FILES) ps $$service 2>/dev/null | grep -q "Up"; then \
			echo "  ✓ $$service"; \
		else \
			echo "  ✗ $$service"; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW)Application Services:$(NC)"
	@for service in $(APP_SERVICES); do \
		if $(COMPOSE) $(COMPOSE_FILES) ps $$service 2>/dev/null | grep -q "Up"; then \
			echo "  ✓ $$service"; \
		else \
			echo "  ✗ $$service"; \
		fi; \
	done

# Development mode
.PHONY: dev
dev: check-env
	@echo "$(GREEN)Starting in development mode...$(NC)"
	@COMPOSE_PROFILES=dev $(COMPOSE) $(COMPOSE_FILES) up

# Run tests
.PHONY: test
test:
	@echo "$(GREEN)Running all tests...$(NC)"
	@cd repos && \
	for repo in */; do \
		if [ -f "$$repo/Makefile" ] && grep -q "test:" "$$repo/Makefile"; then \
			echo "$(YELLOW)Testing $$repo...$(NC)"; \
			cd "$$repo" && make test && cd ..; \
		fi; \
	done

# Build all services
.PHONY: build
build:
	@echo "$(GREEN)Building all services...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) build --parallel

# Clean up
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning up containers and volumes...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) down -v
	@docker system prune -f
	@echo "$(GREEN)Cleanup complete!$(NC)"

# Full reset
.PHONY: reset
reset:
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@$(COMPOSE) $(COMPOSE_FILES) down -v --remove-orphans
	@docker system prune -af
	@echo "$(GREEN)Reset complete!$(NC)"

# Check for port conflicts
.PHONY: check-ports
check-ports:
	@echo "$(GREEN)Checking for port conflicts...$(NC)"
	@ports="3000 3081 4000 5173 5432 6379 8000 9000 9001 9002 27017"; \
	for port in $$ports; do \
		if lsof -i :$$port >/dev/null 2>&1; then \
			echo "$(RED)✗ Port $$port is in use$(NC)"; \
			lsof -i :$$port | grep LISTEN; \
		else \
			echo "$(GREEN)✓ Port $$port is available$(NC)"; \
		fi; \
	done

# Check environment
.PHONY: check-env
check-env:
	@if [ ! -f .env ]; then \
		echo "$(RED)Error: .env file not found!$(NC)"; \
		echo "$(YELLOW)Creating from example...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)Please configure .env file before starting$(NC)"; \
		exit 1; \
	fi

# Backup all data
.PHONY: backup
backup:
	@echo "$(GREEN)Backing up all data...$(NC)"
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@echo "$(YELLOW)Backing up PostgreSQL...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) exec -T postgres pg_dumpall -U $$POSTGRES_USER > backups/$(shell date +%Y%m%d_%H%M%S)/postgres.sql
	@echo "$(YELLOW)Backing up MongoDB...$(NC)"
	@$(COMPOSE) $(COMPOSE_FILES) exec -T mongodb mongodump --archive > backups/$(shell date +%Y%m%d_%H%M%S)/mongodb.archive
	@echo "$(YELLOW)Backing up MinIO...$(NC)"
	@docker run --rm -v minio_data:/data -v $(PWD)/backups/$(shell date +%Y%m%d_%H%M%S):/backup alpine tar czf /backup/minio.tar.gz -C /data .
	@echo "$(GREEN)Backup complete!$(NC)"

# Install dependencies
.PHONY: install-deps
install-deps:
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker is required but not installed$(NC)"; exit 1; }
	@command -v docker compose version >/dev/null 2>&1 || { echo "$(RED)Docker Compose v2 is required but not installed$(NC)"; exit 1; }
	@echo "$(GREEN)All dependencies installed!$(NC)"

# Service-specific commands
.PHONY: logs-%
logs-%:
	@$(COMPOSE) $(COMPOSE_FILES) logs -f $*

.PHONY: restart-%
restart-%:
	@$(COMPOSE) $(COMPOSE_FILES) restart $*

.PHONY: exec-%
exec-%:
	@$(COMPOSE) $(COMPOSE_FILES) exec $* /bin/bash

.PHONY: reset-%
reset-%:
	@$(COMPOSE) $(COMPOSE_FILES) rm -fsv $*
	@$(COMPOSE) $(COMPOSE_FILES) up -d $*