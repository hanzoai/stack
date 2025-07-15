# Hanzo Stack Makefile

.PHONY: help
help:
	@echo "Hanzo Stack Commands:"
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup        - Create .env from example"
	@echo "  make up           - Start all core services (production mode)"
	@echo "  make dev          - Start development environment with hot reload"
	@echo "  make health       - Check health of all services"
	@echo ""
	@echo "Production:"
	@echo "  make up           - Start all core services"
	@echo "  make down         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make ps           - List running services"
	@echo "  make logs         - View logs (all services)"
	@echo "  make logs-chat    - View chat service logs"
	@echo ""
	@echo "Development:"
	@echo "  make dev          - Start with hot reload (compose.dev.yml)"
	@echo "  make dev-up       - Start dev services in background"
	@echo "  make dev-down     - Stop development services"
	@echo "  make dev-status   - Check development services status"
	@echo "  make dev-logs     - Show development logs"
	@echo ""
	@echo "Testing:"
	@echo "  make test         - Test service connectivity"
	@echo "  make test-runtime - Test runtime code execution"
	@echo "  make health       - Check health of all services"
	@echo "  make load-test    - Run load testing"
	@echo ""
	@echo "Profiles:"
	@echo "  make with-api     - Start with API service"
	@echo "  make with-tools   - Start with dev tools (Adminer, Redis Commander)"
	@echo "  make all          - Start all services and tools"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean        - Remove all containers and volumes"
	@echo "  make backup       - Backup databases"
	@echo "  make shell-chat   - Open shell in chat container"
	@echo "  make psql         - Connect to PostgreSQL"
	@echo "  make redis-cli    - Connect to Redis"

# Environment setup
.PHONY: setup
setup:
	@if [ ! -f .env ]; then \
		echo "Creating .env from env.example..."; \
		cp env.example .env; \
	fi
	@echo "Auto-detecting API keys from environment..."
	@for key in OPENAI_API_KEY ANTHROPIC_API_KEY TOGETHER_API_KEY GOOGLE_API_KEY; do \
		if [ -n "$${!key}" ]; then \
			if grep -q "^$$key=" .env; then \
				sed -i "" "s|^$$key=.*|$$key=$${!key}|" .env; \
			else \
				echo "$$key=$${!key}" >> .env; \
			fi; \
			echo "✓ Found $$key"; \
		fi; \
	done
	@echo "Environment setup complete!"

# Production commands
.PHONY: up
up:
	docker compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 10
	@make health

.PHONY: down
down:
	docker compose down

.PHONY: restart
restart:
	docker compose restart

.PHONY: ps
ps:
	docker compose ps

.PHONY: logs
logs:
	docker compose logs -f

.PHONY: logs-%
logs-%:
	docker compose logs -f $*

# Development commands
.PHONY: dev
dev:
	docker compose -f docker-compose.yaml -f compose.dev.yml up

.PHONY: dev-up
dev-up:
	docker compose -f docker-compose.yaml -f compose.dev.yml up -d

.PHONY: dev-down
dev-down:
	docker compose -f docker-compose.yaml -f compose.dev.yml down

# Profile-based commands
.PHONY: with-api
with-api:
	docker compose --profile api up -d

.PHONY: with-tools
with-tools:
	docker compose --profile tools up -d

.PHONY: all
all:
	docker compose --profile api --profile search --profile iam --profile cloud --profile mcp --profile agent --profile tools up -d

.PHONY: stop-dev
stop-dev:
	@echo "Stopping development services..."
	@# Stop LLM Router
	@if [ -f ../llm/.llm.pid ]; then \
		kill $$(cat ../llm/.llm.pid) 2>/dev/null || true; \
		rm ../llm/.llm.pid; \
	fi
	@# Stop Chat2
	@cd ../chat2 && make down 2>/dev/null || true
	@# Stop infrastructure
	@docker compose down 2>/dev/null || docker-compose down
	@echo "✅ All services stopped"

.PHONY: start
start:
	@bash scripts/run-complete-stack.sh

.PHONY: stop
stop:
	@bash scripts/run-complete-stack.sh stop

.PHONY: restart
restart: stop start

# Test service connectivity
.PHONY: test
test:
	@echo "Testing service connectivity..."
	@echo ""
	@echo "Testing LLM Gateway..."
	@curl -s http://localhost:4000/health | jq -r '.status // "Failed"' || echo "Failed to connect"
	@echo ""
	@echo "Testing Chat..."
	@curl -s http://localhost:3081/health || echo "Failed to connect"
	@echo ""
	@echo "Testing Runtime..."
	@curl -s http://localhost:3003/api/health | jq -r '.status // "Failed"' || echo "Failed to connect"
	@echo ""
	@echo "Testing Services Hub..."
	@curl -s http://localhost:3000/health || echo "Failed to connect"

# Test runtime code execution
.PHONY: test-runtime
test-runtime:
	@echo "Testing Runtime Code Execution..."
	@echo ""
	@echo "1. Testing Python execution:"
	@curl -X POST http://localhost:3003/api/execute \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer ${RUNTIME_API_KEY:-dev-runtime-key}" \
		-d '{"language": "python", "code": "print(\"Hello from Hanzo Runtime!\")\nprint(2 + 2)"}' \
		2>/dev/null | jq -r '.output // "Failed"' || echo "Failed to execute Python"
	@echo ""
	@echo "2. Testing JavaScript execution:"
	@curl -X POST http://localhost:3003/api/execute \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer ${RUNTIME_API_KEY:-dev-runtime-key}" \
		-d '{"language": "javascript", "code": "console.log(\"Hello from JS!\"); console.log(3 * 4);"}' \
		2>/dev/null | jq -r '.output // "Failed"' || echo "Failed to execute JavaScript"

# Test complete integration
.PHONY: test-integration
test-integration:
	@bash scripts/test-complete-integration.sh

# Test chat-runtime integration
.PHONY: test-chat-runtime
test-chat-runtime:
	@bash scripts/test-chat-runtime-integration.sh

# Quick start
.PHONY: quickstart
quickstart:
	@bash quickstart.sh

# Health check
.PHONY: health
health:
	@echo "Checking service health..."
	@echo -n "PostgreSQL: " && (docker compose exec -T postgres pg_isready -U hanzo && echo "✓") || echo "✗"
	@echo -n "Redis: " && (docker compose exec -T redis redis-cli --pass hanzo123 ping | grep -q PONG && echo "✓") || echo "✗"
	@echo -n "MongoDB: " && (docker compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" --quiet | grep -q 1 && echo "✓") || echo "✗"
	@echo -n "MinIO: " && (curl -sf http://localhost:9000/minio/health/live > /dev/null && echo "✓") || echo "✗"
	@echo -n "Meilisearch: " && (curl -sf http://localhost:7700/health > /dev/null && echo "✓") || echo "✗"
	@echo -n "LLM Gateway: " && (curl -sf http://localhost:4000/health > /dev/null && echo "✓") || echo "✗"
	@echo -n "Chat: " && (curl -sf http://localhost:3081/health > /dev/null && echo "✓") || echo "✗"
	@echo -n "Runtime: " && (curl -sf http://localhost:3003/api/health > /dev/null && echo "✓") || echo "✗"
	@echo -n "Services: " && (curl -sf http://localhost:3000/health > /dev/null && echo "✓") || echo "✗"


# Maintenance commands
.PHONY: clean
clean:
	docker compose down -v
	docker system prune -f

.PHONY: backup
backup:
	@echo "Creating backup directory..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@echo "Backing up PostgreSQL..."
	docker compose exec -T postgres pg_dumpall -U hanzo > backups/$(shell date +%Y%m%d_%H%M%S)/postgres.sql
	@echo "Backing up MongoDB..."
	docker compose exec -T mongodb mongodump --archive > backups/$(shell date +%Y%m%d_%H%M%S)/mongodb.archive
	@echo "Backup complete in backups/$(shell date +%Y%m%d_%H%M%S)/"

# Development helpers
.PHONY: shell-%
shell-%:
	docker compose exec $* /bin/sh

.PHONY: psql
psql:
	docker compose exec postgres psql -U hanzo

.PHONY: redis-cli
redis-cli:
	docker compose exec redis redis-cli -a hanzo123

.PHONY: mongo-shell
mongo-shell:
	docker compose exec mongodb mongosh -u hanzo -p hanzo123


.PHONY: test-real
test-real:
	@bash scripts/test-real-stack.sh

.PHONY: llm
llm:
	@echo "Starting real LLM service..."
	@cd ../llm && llm --host 0.0.0.0 --port 4000 --config config.yaml

.PHONY: api
api:
	@bash scripts/start-hanzo-api.sh

.PHONY: monitor
monitor:
	@bash scripts/monitor-performance.sh

.PHONY: fix-llm
fix-llm:
	@bash scripts/fix-llm-cost-tracking.sh

.PHONY: status
status:
	@echo "=== Infrastructure Status ==="
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep hanzo || echo "No Hanzo containers"
	@echo ""
	@echo "=== Service Status ==="
	@curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/health >/dev/null && echo "✅ LLM Router: Running" || echo "❌ LLM Router: Not running"
	@curl -sf http://localhost:8000/health >/dev/null && echo "✅ API Service: Running" || echo "❌ API Service: Not running"

.PHONY: load-test
load-test:
	@chmod +x scripts/load-test.sh && ./scripts/load-test.sh

.PHONY: security
security:
	@chmod +x scripts/security-scan.sh && ./scripts/security-scan.sh

.PHONY: deploy
deploy:
	@chmod +x scripts/deploy-production.sh && ./scripts/deploy-production.sh

.PHONY: demo
demo:
	@chmod +x scripts/demo-hanzo-stack.sh && ./scripts/demo-hanzo-stack.sh

.PHONY: dev-status
dev-status:
	@echo "=== Hanzo Development Status ==="
	@echo ""
	@echo "🔍 Checking services..."
	@echo ""
	@# Check infrastructure
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(postgres|redis|mongodb|minio|meilisearch)" || echo "No infrastructure containers running"
	@echo ""
	@# Check LLM Router
	@if curl -sf http://localhost:4000/health >/dev/null; then \
		echo "✅ LLM Router: Running at http://localhost:4000"; \
		echo "   Models: http://localhost:4000/v1/models"; \
	else \
		echo "❌ LLM Router: Not responding"; \
	fi
	@echo ""
	@# Check Chat2
	@if curl -sf http://localhost:3081 >/dev/null; then \
		echo "✅ Chat2: Running at http://localhost:3081"; \
	else \
		echo "❌ Chat2: Not responding (may still be starting)"; \
	fi
	@echo ""
	@# Show process status
	@echo "📊 Running processes:"
	@ps aux | grep -E "(llm.*config.yaml|chat2.*dev)" | grep -v grep || echo "No dev processes found"

.PHONY: dev-logs
dev-logs:
	@echo "=== Development Logs ==="
	@echo ""
	@echo "📝 LLM Router logs:"
	@tail -n 20 ../llm/llm.log 2>/dev/null || echo "No LLM logs found"
	@echo ""
	@echo "📝 Chat2 Backend logs:"
	@tail -n 20 ../chat2/backend.log 2>/dev/null || echo "No Chat2 backend logs found"
	@echo ""
	@echo "📝 Chat2 Frontend logs:"
	@tail -n 20 ../chat2/frontend.log 2>/dev/null || echo "No Chat2 frontend logs found"