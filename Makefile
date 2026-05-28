# Hanzo Stack — OSS quickstart Makefile
# Wraps the common docker compose invocations.

COMPOSE := docker compose -f compose.yml

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Hanzo Stack — OSS quickstart"
	@echo ""
	@echo "Quickstart targets:"
	@echo "  make up           - Start the full stack in the background"
	@echo "  make down         - Stop the stack (volumes preserved)"
	@echo "  make logs         - Tail logs from all services"
	@echo "  make ps           - Show service status"
	@echo "  make restart      - Restart all services"
	@echo "  make pull         - Pull latest images from ghcr.io"
	@echo "  make clean        - Stop and remove all data volumes (DESTRUCTIVE)"
	@echo ""
	@echo "For development of Hanzo services, use: github.com/hanzoai/universe"
	@echo "For production Kubernetes, use:         github.com/hanzoai/operator"

.PHONY: up
up:
	$(COMPOSE) up -d

.PHONY: down
down:
	$(COMPOSE) down

.PHONY: logs
logs:
	$(COMPOSE) logs -f --tail=100

.PHONY: ps
ps:
	$(COMPOSE) ps

.PHONY: restart
restart:
	$(COMPOSE) restart

.PHONY: pull
pull:
	$(COMPOSE) pull

.PHONY: clean
clean:
	$(COMPOSE) down -v
