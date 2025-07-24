# Hanzo Stack Makefile
# Primary interface for managing the Hanzo AI infrastructure

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default compose files
COMPOSE := docker compose
COMPOSE_DEV := docker compose -f compose.dev.yml
COMPOSE_INFRA := docker compose -f compose.infra.yml

# Default target
.DEFAULT_GOAL := help

# ===== Help =====
.PHONY: help
help:
	@echo "$(BLUE)Hanzo Stack Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  make setup         - Configure environment from template"
	@echo "  make infra         - Start infrastructure services only"
	@echo "  make up            - Start all services (requires ghcr.io images)"
	@echo "  make dev           - Start development mode with hot reload"
	@echo "  make status        - Check service status"
	@echo ""
	@echo "$(YELLOW)Service Management:$(NC)"
	@echo "  make start         - Start all core services"
	@echo "  make stop          - Stop all services"
	@echo "  make restart       - Restart all services"
	@echo "  make ps            - List running services"
	@echo "  make health        - Health check all services"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  make dev           - Start with hot reload (foreground)"
	@echo "  make dev-up        - Start development mode (background)"
	@echo "  make dev-down      - Stop development services"
	@echo "  make dev-logs      - Show development logs"
	@echo "  make dev-status    - Check development service status"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  make test          - Run integration tests"
	@echo "  make test-api      - Test API endpoints"
	@echo "  make test-router   - Test router functionality"
	@echo "  make test-full     - Run all tests"
	@echo ""
	@echo "$(YELLOW)Profiles:$(NC)"
	@echo "  make tools         - Start with dev tools (Adminer, etc.)"
	@echo "  make full          - Start all services including optional"
	@echo ""
	@echo "$(YELLOW)Logs:$(NC)"
	@echo "  make logs          - View all logs"
	@echo "  make logs-router   - View router logs"
	@echo "  make logs-chat     - View chat logs"
	@echo "  make logs-cloud    - View cloud logs"
	@echo ""
	@echo "$(YELLOW)Database Access:$(NC)"
	@echo "  make psql          - Connect to PostgreSQL"
	@echo "  make redis-cli     - Connect to Redis"
	@echo "  make mongo-shell   - Connect to MongoDB"
	@echo ""
	@echo "$(YELLOW)Maintenance:$(NC)"
	@echo "  make clean         - Remove containers and volumes"
	@echo "  make reset         - Full reset (WARNING: deletes data)"
	@echo "  make backup        - Backup all databases"
	@echo "  make update        - Pull latest images"

# ===== Setup =====
.PHONY: setup
setup:
	@echo "$(BLUE)Setting up Hanzo Stack environment...$(NC)"
	@./scripts/setup-env.sh

# ===== Quick Start =====
.PHONY: up
up: setup
	@echo "$(BLUE)Starting Hanzo Stack...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)Waiting for services to be healthy...$(NC)"
	@./scripts/wait-for-healthy.sh
	@make status

.PHONY: infra
infra: setup
	@echo "$(BLUE)Starting infrastructure services...$(NC)"
	@$(COMPOSE_INFRA) up -d
	@echo "$(GREEN)Infrastructure services started!$(NC)"
	@echo "PostgreSQL: localhost:5432"
	@echo "Redis: localhost:6379"
	@echo "MongoDB: localhost:27017"
	@echo "MinIO: localhost:9000 (Console: localhost:9001)"
	@echo "Meilisearch: localhost:7700"

.PHONY: start
start: up

.PHONY: dev
dev: setup
	@echo "$(BLUE)Starting Hanzo Stack in development mode...$(NC)"
	@$(COMPOSE_DEV) up

.PHONY: dev-up
dev-up: setup
	@echo "$(BLUE)Starting Hanzo Stack in development mode (background)...$(NC)"
	@$(COMPOSE_DEV) up -d
	@./scripts/wait-for-healthy.sh
	@make status

# ===== Service Management =====
.PHONY: stop down
stop down:
	@echo "$(BLUE)Stopping Hanzo Stack...$(NC)"
	@$(COMPOSE) down

.PHONY: restart
restart:
	@echo "$(BLUE)Restarting Hanzo Stack...$(NC)"
	@$(COMPOSE) restart
	@./scripts/wait-for-healthy.sh

.PHONY: ps
ps:
	@$(COMPOSE) ps

.PHONY: status
status:
	@./scripts/check-status.sh

.PHONY: health
health:
	@./scripts/health-check.sh

# ===== Development =====
.PHONY: dev-down
dev-down:
	@echo "$(BLUE)Stopping development services...$(NC)"
	@$(COMPOSE_DEV) down

.PHONY: dev-logs
dev-logs:
	@$(COMPOSE_DEV) logs -f

.PHONY: dev-status
dev-status:
	@echo "$(BLUE)Development Service Status:$(NC)"
	@$(COMPOSE_DEV) ps
	@echo ""
	@./scripts/check-dev-services.sh

# ===== Testing =====
.PHONY: test
test:
	@echo "$(BLUE)Running integration tests...$(NC)"
	@./scripts/test-integration.sh

.PHONY: test-api
test-api:
	@echo "$(BLUE)Testing API endpoints...$(NC)"
	@./scripts/test-api-endpoints.sh

.PHONY: test-router
test-router:
	@echo "$(BLUE)Testing router functionality...$(NC)"
	@./scripts/test-router.sh

.PHONY: test-full
test-full: test-api test-router test
	@echo "$(GREEN)All tests completed!$(NC)"

# ===== Profiles =====
.PHONY: tools
tools:
	@echo "$(BLUE)Starting with development tools...$(NC)"
	@COMPOSE_PROFILES=tools $(COMPOSE) up -d

.PHONY: full
full:
	@echo "$(BLUE)Starting full stack with all services...$(NC)"
	@COMPOSE_PROFILES=tools,full $(COMPOSE_DEV) up -d

# ===== Logs =====
.PHONY: logs
logs:
	@$(COMPOSE) logs -f

.PHONY: logs-%
logs-%:
	@$(COMPOSE) logs -f $*

# ===== Database Access =====
.PHONY: psql
psql:
	@echo "$(BLUE)Connecting to PostgreSQL...$(NC)"
	@$(COMPOSE) exec postgres psql -U ${POSTGRES_USER:-hanzo} ${POSTGRES_DB:-hanzo}

.PHONY: redis-cli
redis-cli:
	@echo "$(BLUE)Connecting to Redis...$(NC)"
	@$(COMPOSE) exec redis redis-cli -a ${REDIS_PASSWORD:-hanzo123}

.PHONY: mongo-shell
mongo-shell:
	@echo "$(BLUE)Connecting to MongoDB...$(NC)"
	@$(COMPOSE) exec mongodb mongosh -u ${MONGO_ROOT_USERNAME:-hanzo} -p ${MONGO_ROOT_PASSWORD:-hanzo123}

# ===== Shell Access =====
.PHONY: shell-%
shell-%:
	@echo "$(BLUE)Opening shell in $* container...$(NC)"
	@$(COMPOSE) exec $* /bin/sh

# ===== Maintenance =====
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning up containers and volumes...$(NC)"
	@$(COMPOSE) down -v
	@docker system prune -f

.PHONY: reset
reset:
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@$(COMPOSE) down -v
	@rm -rf workspace/*
	@echo "$(GREEN)Reset complete.$(NC)"

.PHONY: backup
backup:
	@echo "$(BLUE)Creating backup...$(NC)"
	@./scripts/backup-databases.sh

.PHONY: update
update:
	@echo "$(BLUE)Pulling latest images...$(NC)"
	@$(COMPOSE) pull
	@echo "$(GREEN)Images updated. Run 'make restart' to apply.$(NC)"

# ===== Advanced Operations =====
.PHONY: scale-%
scale-%:
	@echo "$(BLUE)Scaling $* service...$(NC)"
	@$(COMPOSE) up -d --scale $*=3

.PHONY: exec
exec:
	@echo "$(BLUE)Executing command in service...$(NC)"
	@echo "Usage: make exec service=router cmd='ls -la'"
	@$(COMPOSE) exec $(service) $(cmd)

# ===== Demo & Examples =====
.PHONY: demo
demo:
	@echo "$(BLUE)Running Hanzo Stack demo...$(NC)"
	@./scripts/demo-stack.sh

.PHONY: example-chat
example-chat:
	@echo "$(BLUE)Opening example chat completion...$(NC)"
	@./scripts/example-chat-completion.sh

# ===== CI/CD =====
.PHONY: ci-test
ci-test:
	@echo "$(BLUE)Running CI tests...$(NC)"
	@./scripts/ci-test.sh

.PHONY: build
build:
	@echo "$(BLUE)Pulling all images...$(NC)"
	@$(COMPOSE) pull

# ===== Utilities =====
.PHONY: check-ports
check-ports:
	@echo "$(BLUE)Checking for port conflicts...$(NC)"
	@./scripts/check-ports.sh

.PHONY: env-info
env-info:
	@echo "$(BLUE)Environment Information:$(NC)"
	@./scripts/show-env-info.sh

# ===== Documentation =====
.PHONY: docs
docs:
	@echo "$(BLUE)Opening documentation...$(NC)"
	@python -m http.server -d docs 8888