# Hanzo Stack Makefile
# Primary interface for managing the Hanzo AI infrastructure

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default compose files (single, DRY)
COMPOSE := docker compose -f compose.yml
COMPOSE_DEV := docker compose -f compose.dev.yml

# Default target
.DEFAULT_GOAL := help

# ===== Help =====
.PHONY: help
help:
	@echo "$(BLUE)Hanzo Stack Management$(NC)"
	@echo ""
    @echo "$(YELLOW)Quick Start:$(NC)"
    @echo "  make setup         - Configure environment from template"
    @echo "  make up            - Start production stack (images)"
    @echo "  make dev-up        - Start dev stack (build from submodules)"
    @echo "  make status        - Check service status"
    @echo "  make logs          - View logs"
    @echo "  make restart       - Restart all services"
	@echo ""
	@echo "$(YELLOW)Service Management:$(NC)"
	@echo "  make start         - Start all core services"
	@echo "  make stop          - Stop all services"
	@echo "  make restart       - Restart all services"
	@echo "  make ps            - List running services"
	@echo "  make health        - Health check all services"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  make dev           - Start dev stack (foreground)"
	@echo "  make dev-up        - Start dev stack (background)"
	@echo "  make dev-down      - Stop development services"
	@echo "  make dev-logs      - Show development logs"
	@echo "  make dev-status    - Check development service status"
	@echo "  make infra         - Start only infra (db/redis/etc)"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  make test          - Run integration tests"
	@echo "  make test-api      - Test API endpoints"
	@echo "  make test-router   - Test router functionality"
	@echo "  make test-full     - Run all tests"
	@echo ""
    @echo "$(YELLOW)Submodules & Sources:$(NC)"
    @echo "  make submodules-ensure   - Add/init/update all core submodules"
    @echo "  make submodules-status   - Show submodule status"
    @echo "  make submodules-update   - Fast-forward all submodules"
    @echo "  make submodules-normalize-urls - Normalize remotes to https"
	@echo ""
    @echo "$(YELLOW)Profiles:$(NC)"
    @echo "  make tools         - Start dev tools (Adminer, etc.)"
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
	@echo "$(BLUE)Starting Hanzo Stack (production images)...$(NC)"
	@$(COMPOSE) up -d
	@./scripts/wait-for-healthy.sh || true
	@make status

.PHONY: infra
infra: setup
	@echo "$(BLUE)Starting infrastructure services...$(NC)"
	@$(COMPOSE) up -d postgres redis mongodb minio meilisearch
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
	@./scripts/wait-for-healthy.sh || true
	@make status

.PHONY: ps
ps:
	@$(COMPOSE) ps

.PHONY: status
status:
	@echo "$(BLUE)Hanzo Stack Status:$(NC)"
	@echo ""
	@echo "$(YELLOW)Running Services:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep hanzo || echo "  No services running"
	@echo ""
	@echo "$(GREEN)Service URLs:$(NC)"
	@echo "  LLM Gateway:     http://localhost:4000"
	@echo "  Chat:            http://localhost:3081"
	@echo "  Search:          http://localhost:3000"
	@echo "  Build:           http://localhost:3002"
	@echo "  IDE:             http://localhost:3005"
	@echo "  Runtime:         http://localhost:3003"
	@echo "  MCP Server:      http://localhost:3004"
	@echo "  Operative VNC:   http://localhost:6080"
	@echo "  Platform:        http://localhost:3006"
	@echo "  Flow:            http://localhost:3007"
	@echo "  Agent API:       http://localhost:8001"
	@echo ""
	@echo "$(YELLOW)Infrastructure:$(NC)"
	@echo "  PostgreSQL:      localhost:5432     $(shell docker ps -q -f name=hanzo-postgres > /dev/null 2>&1 && echo "[$(GREEN)✓$(NC)]" || echo "[$(RED)✗$(NC)]")"
	@echo "  Redis:           localhost:6379     $(shell docker ps -q -f name=hanzo-redis > /dev/null 2>&1 && echo "[$(GREEN)✓$(NC)]" || echo "[$(RED)✗$(NC)]")"
	@echo "  MongoDB:         localhost:27017    $(shell docker ps -q -f name=hanzo-mongodb > /dev/null 2>&1 && echo "[$(GREEN)✓$(NC)]" || echo "[$(RED)✗$(NC)]")"
	@echo "  MinIO:           localhost:9000     $(shell docker ps -q -f name=hanzo-minio > /dev/null 2>&1 && echo "[$(GREEN)✓$(NC)]" || echo "[$(RED)✗$(NC)]")"
	@echo "  Meilisearch:     localhost:7700     $(shell docker ps -q -f name=hanzo-meilisearch > /dev/null 2>&1 && echo "[$(GREEN)✓$(NC)]" || echo "[$(RED)✗$(NC)]")"

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
	@COMPOSE_PROFILES=tools $(COMPOSE_DEV) up -d

.PHONY: full
full:
	@echo "$(BLUE)Starting dev stack with tools...$(NC)"
	@COMPOSE_PROFILES=tools $(COMPOSE_DEV) up -d

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

# ===== Submodules & Sources =====
.PHONY: submodules-init
submodules-init:
	@echo "$(BLUE)Initializing git submodules (recursive)...$(NC)"
	@git submodule update --init --recursive

.PHONY: submodules-update
submodules-update:
	@echo "$(BLUE)Syncing and updating submodules to remote HEAD...$(NC)"
	@git submodule sync --recursive
	@git submodule update --init --recursive
	@git submodule foreach --recursive 'git fetch --all --prune || true'
	@git submodule foreach --recursive 'branch=$$(git symbolic-ref -q --short HEAD || echo main); echo "Updating $$name ($$branch)"; git pull --ff-only origin $$branch || true'

.PHONY: submodules-status
submodules-status:
	@echo "$(BLUE)Submodule status (recursive):$(NC)"
	@git submodule status --recursive || echo "No submodules detected."

# Add common Hanzo repos as submodules if missing
# Map repo -> path inside stack
HANZO_ORG ?= hanzoai
define ADD_SUBMODULE
  @if [ ! -d "$(2)/.git" ]; then \
    echo "$(YELLOW)Adding submodule: $(2) -> https://github.com/$(HANZO_ORG)/$(1).git$(NC)"; \
    mkdir -p "$(dir $(2))"; \
    git submodule add --force https://github.com/$(HANZO_ORG)/$(1).git "$(2)" || true; \
  else \
    echo "$(GREEN)Submodule present: $(2)$(NC)"; \
  fi
endef

.PHONY: submodules-add-core
submodules-add-core:
	@echo "$(BLUE)Ensuring core Hanzo submodules exist...$(NC)"
	$(call ADD_SUBMODULE,llm,services/llm)
	$(call ADD_SUBMODULE,chat,services/chat)
	$(call ADD_SUBMODULE,search,services/search)
	$(call ADD_SUBMODULE,cloud,cloud)
	$(call ADD_SUBMODULE,runtime,runtime)
	$(call ADD_SUBMODULE,iam,iam)
	$(call ADD_SUBMODULE,mcp,mcp)
	$(call ADD_SUBMODULE,platform,platform)
	$(call ADD_SUBMODULE,analytics,analytics)
	$(call ADD_SUBMODULE,ide,ide)
	$(call ADD_SUBMODULE,js-sdk,js-sdk)
	$(call ADD_SUBMODULE,python-sdk,python-sdk)
	$(call ADD_SUBMODULE,sdk,sdk)
	$(call ADD_SUBMODULE,agent,libs/agent)
	$(call ADD_SUBMODULE,jin,services/jin)
	$(call ADD_SUBMODULE,az2,services/az2)
	@echo "$(GREEN)Core submodule check complete.$(NC)"

.PHONY: submodules-ensure
submodules-ensure: submodules-add-core submodules-init submodules-update submodules-status
	@echo "$(GREEN)Submodules ensured and up-to-date.$(NC)"

.PHONY: submodules-normalize-urls
submodules-normalize-urls:
	@echo "$(BLUE)Normalizing submodule URLs to https://github.com/$(HANZO_ORG) ...$(NC)"
	@set -e; \
  normalize() { \
    name="$$1"; repo="$$2"; \
    if git config -f .gitmodules --get submodule.$$name.path >/dev/null 2>&1; then \
      echo " - $$name -> https://github.com/$(HANZO_ORG)/$$repo.git"; \
      git config -f .gitmodules submodule.$$name.url https://github.com/$(HANZO_ORG)/$$repo.git; \
    fi; \
  }; \
  normalize mcp mcp; \
  normalize platform platform; \
  normalize build build; \
  normalize python-sdk python-sdk; \
  normalize js-sdk js-sdk; \
  normalize operative operative; \
  echo "$(GREEN)Updated .gitmodules. Run 'git submodule sync' next.$(NC)"

# ===== Build images from local source (best-effort) =====
# No explicit image-build pathway; dev uses compose.dev.yml builds for DRY
