# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Hanzo Stack Architecture

The Hanzo Stack is a microservices-based AI infrastructure platform using Docker Compose. Services communicate through internal Docker networks, with the Router service acting as the central LLM gateway.

### Service Communication Pattern
- **Router (port 4000)** is the central LLM gateway that all services use for AI requests
- **Team (port 8087)** provides project management, tasks, documents, and collaboration
- Services route through internal Docker network names (e.g., `http://router:8000`)
- Router handles provider selection, cost tracking, and sends analytics to Cloud service
- Chat service uses Runtime for code execution and MCP for file operations
- All database connections use internal Docker networks

### Git Submodules Structure
The project uses git submodules for modular development. Key submodules:
- `services/llm` - Router/LLM Gateway implementation
- `services/chat` - Chat interface
- `services/search`, `services/cloud`, `services/runtime` - Core services
- `iam/`, `mcp/`, `platform/` - Platform infrastructure
- `sdk/`, `js-sdk/`, `python-sdk/` - Client SDKs

## Essential Development Commands

### Quick Development Workflow
```bash
# Initial setup (copies .env.example to .env)
make setup

# Start development mode with hot reload
make dev

# View logs for debugging
make dev-logs

# Run tests
npm test  # Runs Jest integration tests against real services

# Check service health
make health
make status
```

### Testing Commands
```bash
# Run all integration tests (uses real databases/services)
npm test

# Run specific test suites
npm run test:router   # Test Router/LLM Gateway
npm run test:ide      # Test IDE service
npm run test:stack    # Full stack integration test

# Makefile test commands
make test            # Run integration tests
make test-router     # Test router functionality
make test-full       # Run all tests
```

### Database Access
```bash
make psql          # Connect to PostgreSQL
make redis-cli     # Connect to Redis
make mongo-shell   # Connect to MongoDB
```

### Service Management
```bash
make restart       # Restart all services
make stop          # Stop services
make clean         # Remove containers and volumes
make logs SERVICE=router  # View specific service logs
```

## Development Configuration

### Environment Setup
The `.env` file requires at least one LLM provider API key:
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or other supported provider
- Router auto-detects available providers from environment variables

### Docker Compose Files
- `compose.yml` - Production with pre-built images from ghcr.io
- `compose.dev.yml` - Development with source mounting and hot reload
- `docker-compose.essential.yml` - Core services only
- `docker-compose.batteries.yml` - Full stack with all optional services

### Configuration Files
- `config/router-config.yaml` - LLM provider routing and model aliases
- `config/router-extensions.py` - Custom router logic
- `config/ide-config.toml` - IDE service settings

## Testing Architecture

Tests use Jest with real service connections (no mocks):
- Tests in `tests/integration/` connect to actual databases and services
- CI runs tests with real PostgreSQL, Redis, MongoDB via GitHub Actions
- Test timeout is 30 seconds for service startup
- Tests verify end-to-end workflows including LLM requests and analytics

## Service Ports Reference

| Service | Port | Internal Port |
|---------|------|---------------|
| Router | 4000 | 8000 |
| Chat | 3081 | 8080 |
| Cloud | 3001 | 3000 |
| IDE | 3002 | 3000 |
| Runtime | 3003 | 8001 |
| Search | 3000 | 8080 |
| PostgreSQL | 5432 | 5432 |
| Redis | 6379 | 6379 |
| MongoDB | 27017 | 27017 |

## Key Implementation Notes

1. **Router is central** - All LLM requests must go through Router service for tracking and routing
2. **Database per service** - Each service uses its own PostgreSQL schema or separate database
3. **Hot reload in dev** - Development mode mounts source directories for immediate code changes
4. **Real integration tests** - Tests connect to actual services, not mocks
5. **Environment-based config** - Services auto-configure based on environment variables
6. **Git submodules** - Use `make submodules-ensure` to keep submodules updated