# Hanzo Stack Quick Start

## Prerequisites
- Docker Desktop with 32GB+ RAM allocated
- 100GB+ free disk space
- macOS, Linux, or WSL2 on Windows

## Quick Start (5 minutes)

1. **Clone and configure:**
```bash
git clone https://github.com/hanzoai/stack.git
cd stack
cp .env.example .env
# Edit .env with your API keys (optional for testing)
```

2. **Start core services only:**
```bash
make up-core
# This starts: PostgreSQL, Redis, MinIO, MongoDB, Meilisearch, ClickHouse
```

3. **Start AI services:**
```bash
make up-ai
# This starts: LLM Gateway, Chat, MCP, Agent, Operative
```

4. **Check health:**
```bash
make health
```

## Service URLs

Once running, access services at:

- **Chat UI**: http://localhost:3081
- **Search**: http://localhost:3000
- **API**: http://localhost:8000/docs
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **LLM Gateway**: http://localhost:4000/docs

## Test with Mock Services

Run without external API keys:
```bash
# Start mock services
docker compose -f docker-compose.mocks.yml up -d

# Start stack with mocks
MOCK_EXTERNAL_APIS=true make up
```

## Run Integration Tests

```bash
# Run all tests
docker compose -f docker-compose.test.yml run integration-tests

# Run specific test
docker compose -f docker-compose.test.yml run integration-tests \
  pytest tests/integration/test_full_stack.py::TestFullStackIntegration::test_llm_gateway_routing
```

## Common Commands

```bash
make logs           # View all logs
make logs-chat      # View specific service logs
make restart-api    # Restart specific service
make down           # Stop everything
make clean          # Clean up (preserves data)
make reset          # Full reset (WARNING: deletes data)
```

## Minimal Setup (Core + 1 Service)

Just want to test one service? Start only what you need:

```bash
# For Chat only
docker compose up -d postgres redis mongodb llm-gateway chat

# For API only  
docker compose up -d postgres redis minio api

# For Search only
docker compose up -d postgres meilisearch search
```

## Troubleshooting

### Out of memory
```bash
# Check Docker memory
docker system df
docker system prune -a

# Increase Docker Desktop memory to 32GB+
```

### Port conflicts
```bash
make check-ports
# Kill conflicting processes or change ports in .env
```

### Service won't start
```bash
# Check specific service logs
docker compose logs <service-name>

# Restart service
docker compose restart <service-name>
```

## Next Steps

- Read the full [README](README.md) for detailed documentation
- Check [integration tests](tests/integration/) for usage examples
- Join our Discord for support: https://discord.gg/hanzoai