# Hanzo Stack

Complete AI infrastructure stack for running all Hanzo services together with seamless integration.

## Overview

The Hanzo Stack provides a unified environment for running the core Hanzo AI services:

- **Router (LLM Gateway)** - Unified API for 100+ LLM providers with cost tracking
- **Chat** - AI chat interface with MCP integration and code execution
- **Cloud** - AI Console, AI Infrastructure management and API usage analytics
- **IAM** - Core Backend Identity and authentication services
- **Search** - AI-powered search engine frontend
- **Runtime** - Secure code execution environment
- **Flow** - Visual workflow builder
- **App Builder** - A low-code platform for building AI-powered applications

## Quick Start

```bash
# Clone this repository
git clone https://github.com/hanzoai/stack.git
cd stack

# Setup environment (copies env.example to .env)
make setup

# Edit .env and add your API keys (at least one LLM provider)
# Required: OPENAI_API_KEY, ANTHROPIC_API_KEY, or other provider

# Start the stack
make up

# Or start in development mode with local repos
make dev

# Check service status
make status
```

## Prerequisites

- Docker and Docker Compose v2+
- At least one LLM provider API key (OpenAI, Anthropic, etc.)
- 8GB RAM minimum (16GB recommended for full stack)

## Service Architecture

### Core Services

| Service | Port | Description |
|---------|------|-------------|
| App | 4000 | LLM Gateway - Routes requests to 100+ providers |
| Router | 4000 | LLM Gateway - Routes requests to 100+ providers |
| Chat | 3081 | Chat UI with code execution and MCP tools |
| Cloud | 3001 | Dashboard for API tracking and analytics |
| App Builder | 3002 | Low-code platform for building AI-powered applications |

| Search | 3000 | AI-powered search engine |
| Runtime | 3003 | Secure code execution environment |
| Flow | 3006 | Visual workflow builder |

### Infrastructure

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Primary database with pgvector |
| Redis | 6379 | Caching and queues |
| MongoDB | 27017 | Chat message storage |
| MinIO | 9000/9001 | S3-compatible object storage |
| Meilisearch | 7700 | Full-text search for Chat |

### Development Tools (--tools flag)

| Tool | Port | Description |
|------|------|-------------|
| Adminer | 8081 | Database UI |
| Redis Commander | 8082 | Redis UI |
| Mongo Express | 8083 | MongoDB UI |

## Key Features

### 1. Unified LLM Gateway (Router)

- Single API endpoint for all LLM providers
- Automatic provider detection based on available API keys
- Cost tracking and usage analytics sent to Cloud
- Request routing and load balancing
- Supports OpenAI, Anthropic, Google, Together AI, and 20+ more

### 2. Integrated Chat Experience

- Multiple LLM providers via Router integration
- Code execution through Runtime service
- MCP tools for file operations and search
- Persistent chat history in MongoDB
- Optional Clerk authentication

### 3. Cloud Dashboard Integration

- Real-time API usage tracking from Router
- Cost analytics per user/project
- Service health monitoring
- User and project management

### 4. Secure Code Execution

- Sandboxed execution via Runtime service
- Support for Python, JavaScript, TypeScript, Bash
- Resource limits and timeouts
- Direct integration with Chat for interactive coding

## Makefile Commands

```bash
# Quick Start
make help          # Show all available commands
make setup         # Configure environment
make up            # Start production stack
make dev           # Start development mode
make status        # Check service status

# Service Management
make stop          # Stop all services
make restart       # Restart services
make ps            # List running services
make health        # Health check all services

# Development
make dev-up        # Start dev mode in background
make dev-logs      # Show development logs
make tools         # Start with dev tools (Adminer, etc.)
make full          # Start all services including optional

# Testing
make test          # Run integration tests
make test-router   # Test router functionality
make test-full     # Run all tests

# Database Access
make psql          # Connect to PostgreSQL
make redis-cli     # Connect to Redis
make mongo-shell   # Connect to MongoDB

# Maintenance
make clean         # Remove containers and volumes
make backup        # Backup all databases
make update        # Pull latest images
```

## Development Mode

When using `make dev`, the stack:
- Mounts local repositories for hot-reload development
- Enables debug logging across all services
- Skips authentication for easier testing
- Provides development tools with `--tools` flag



## API Integration Examples

### Using the Router

All services route LLM requests through the Router for unified access:

```bash
# Example: Chat completion
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-router-master-hanzo" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'
```

### Service Integration Flow

1. **Chat** → Makes LLM requests to **Router**
2. **Router** → Routes to appropriate provider (OpenAI, Anthropic, etc.)
3. **Router** → Tracks usage and sends analytics to **Cloud**
4. **Cloud** → Displays usage dashboard and cost tracking
5. **Chat** → Can execute code via **Runtime** service
6. **Chat** → Uses **MCP** for file operations and tools

## Environment Configuration

Key environment variables in `.env`:

```bash
# LLM Providers (configure at least one)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...
TOGETHER_API_KEY=...

# Service Configuration
ROUTER_MASTER_KEY=sk-router-master-hanzo
ROUTER_UI_USERNAME=admin
ROUTER_UI_PASSWORD=admin

# Development Settings
NODE_ENV=production  # or development
SKIP_AUTH=true       # Skip auth in dev
ENABLE_COST_TRACKING=true
ENABLE_API_TRACKING=true
```

## Troubleshooting

### Check Service Health

```bash
# View all service statuses
docker compose ps

# Check specific service logs
docker compose logs router -f
docker compose logs chat -f

# Test service endpoints
curl http://localhost:4000/health      # Router
curl http://localhost:3081/api/health  # Chat
curl http://localhost:3001/api/health  # Cloud
```

### Common Issues

1. **No API keys configured**
   ```bash
   # Add at least one provider key to .env
   OPENAI_API_KEY=sk-...
   # Router auto-detects and enables providers
   ```

2. **Port conflicts**
   ```bash
   # Check for conflicts
   make check-ports

   # Override in .env
   ROUTER_PORT=4001
   ```

3. **Services not connecting**
   ```bash
   # Check health and restart
   make health
   make restart
   ```

## Advanced Configuration

### Custom Router Configuration

Edit `config/router-config.yaml` for:
- Model aliases and routing rules
- Provider preferences and fallbacks
- Rate limiting and quotas
- Cost tracking customization

### Enable Optional Services

```bash
# Start with development tools
make tools

# Start full stack with all services
make full
```

## Security Notes

- Default credentials are for development only
- In production:
  - Change all default passwords
  - Enable proper authentication (Clerk, NextAuth)
  - Use TLS/HTTPS for external access
  - Review security settings per service

## Contributing

Contributions welcome! See individual service repositories for guidelines.

## License

MIT License - see individual service licenses for details.
