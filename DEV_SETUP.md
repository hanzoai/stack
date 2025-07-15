# Hanzo Stack Development Setup

This guide explains how to run the Hanzo Stack in development mode with hot reload enabled.

## Overview

The `make dev` command starts:
- Infrastructure services (PostgreSQL, Redis, MongoDB, MinIO, Meilisearch)
- LLM Router on port 4000 (from ~/work/hanzo/llm)
- Chat2 interface on port 3081 (from ~/work/hanzo/chat2)

All services use local code repositories with hot reload enabled where possible.

## Quick Start

```bash
cd ~/work/hanzo/stack
make dev
```

Wait about 30 seconds for all services to start, then access:
- Chat Interface: http://localhost:3081
- LLM Router: http://localhost:4000
- Models List: http://localhost:4000/v1/models

## Development Workflow

### Hot Reload

**Chat2 (Frontend & Backend)**
- Edit files in `~/work/hanzo/chat2`
- Changes reload automatically
- Frontend: React components, styles, etc.
- Backend: API endpoints, middleware, etc.

**LLM Router**
- Edit files in `~/work/hanzo/llm`
- Restart required: `make stop-dev && make dev`

### Check Service Status

```bash
make dev-status
```

Shows:
- Running containers
- Service health checks
- Process status

### View Logs

```bash
make dev-logs
```

Or tail specific logs:
```bash
tail -f ~/work/hanzo/llm/llm.log
tail -f ~/work/hanzo/chat2/backend.log
tail -f ~/work/hanzo/chat2/frontend.log
```

### Stop Services

```bash
make stop-dev
```

## Configuration

### Environment Variables

The setup script creates:
- `~/work/hanzo/chat2/.env` - Chat2 configuration
- `~/work/hanzo/chat2/chat.yaml` - Chat2 settings
- `~/work/hanzo/llm/config.yaml` - LLM Router config

### Key Settings

**Chat2 (.env)**
```env
PORT=3081
ENDPOINTS_HANZO_BASEURL=http://localhost:4000/v1
ENDPOINTS_HANZO_APIKEY=sk-hanzo-local-dev
```

**LLM Router (config.yaml)**
```yaml
general_settings:
  master_key: sk-hanzo-local-dev
  database_url: "postgresql://hanzo:hanzo123@localhost:5432/llm?sslmode=disable"
```

## Available Features

### Models
- Access all models configured in LLM Router
- View available models: http://localhost:4000/v1/models
- Models appear in Chat2 model selector

### MCP Servers
The following MCP servers are configured:
- **hanzo-mcp**: Full Hanzo MCP toolkit
- **filesystem**: File system operations
- **code**: Code search and analysis
- **web**: Web scraping and automation

### Infrastructure Services
- **PostgreSQL**: localhost:5432 (user: hanzo, pass: hanzo123)
- **Redis**: localhost:6379
- **MongoDB**: localhost:27017
- **MinIO**: localhost:9000 (console: localhost:9001)
- **Meilisearch**: localhost:7700

## Troubleshooting

### Services Not Starting

1. Check Docker is running:
```bash
docker ps
```

2. Check for port conflicts:
```bash
lsof -i :4000  # LLM Router
lsof -i :3081  # Chat2
```

3. View detailed logs:
```bash
make dev-logs
```

### Models Not Showing in UI

1. Check LLM Router is running:
```bash
curl http://localhost:4000/health
```

2. Check models endpoint:
```bash
curl http://localhost:4000/v1/models
```

3. Verify chat.yaml has `fetch: true` under models

### MCP Servers Not Available

1. Ensure hanzo-mcp is installed:
```bash
which hanzo-mcp
```

2. Check chat.yaml has mcpServers configured

3. Restart Chat2 backend

## Adding New Services

To add a new service to the dev environment:

1. Update `docker-compose.dev.yml` if using containers
2. Add startup commands to the `make dev` target
3. Add status checks to `make dev-status`
4. Add log paths to `make dev-logs`

## Tips

- Use `make dev-status` frequently to check service health
- Keep terminal tabs open with `tail -f` on log files
- Edit `.env` files to add API keys for different providers
- The setup is designed for rapid iteration - most changes don't require restarts