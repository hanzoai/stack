# Hanzo Stack

Complete Hanzo AI infrastructure stack for local development and production deployment.

## Quick Start

### Production Mode (using published images)
```bash
# Start all core services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Development Mode (with hot reload)
```bash
# Start with development overrides
docker compose -f docker-compose.yaml -f compose.dev.yml up

# Start specific services only
docker compose -f docker-compose.yaml -f compose.dev.yml up chat runtime services

# Enable additional services (profiles)
docker compose -f docker-compose.yaml -f compose.dev.yml --profile api --profile tools up
```

## Services

### Core Services (Always Running)

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Main database |
| Redis | 6379 | Cache and queue |
| MongoDB | 27017 | Document store (for Chat) |
| MinIO | 9000/9001 | S3-compatible storage |
| Meilisearch | 7700 | Search engine |
| LLM Gateway | 4000 | Unified LLM proxy |
| Chat | 3081 | AI chat interface |
| Services | 3000 | Service orchestration hub |
| Runtime | 3003 | Code execution engine |

### Optional Services (via Profiles)

Enable with `--profile <name>`:

- `api` - Core API service (port 8000)
- `search` - AI search engine (port 3000)
- `iam` - Identity management (port 8080)
- `cloud` - Cloud platform (port 3001)
- `mcp` - Model Context Protocol (port 3004)
- `agent` - Agent SDK (port 3005)
- `tools` - Development tools (Adminer, Redis Commander)

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Required API Keys (at least one)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
TOGETHER_API_KEY=...

# Optional: Custom ports
CHAT_PORT=3081
LLM_PORT=4000
RUNTIME_PORT=3003

# Optional: Custom paths for development
CHAT_PATH=../chat
LLM_PATH=../llm
RUNTIME_PATH=../runtime
SERVICES_PATH=../services/services
```

### Development Paths

The development compose file expects services to be cloned as siblings:

```
hanzo/
├── stack/          # This repository
├── chat/           # Chat service
├── llm/            # LLM gateway
├── runtime/        # Runtime engine
├── services/       # Services hub
├── api/            # API service
├── search/         # Search service
└── ...             # Other services
```

## Runtime Integration

The runtime engine is integrated into the stack for code execution:

1. **Chat Integration**: Chat can execute code through the runtime API
2. **Security**: Runtime uses Docker containers for isolation
3. **Development**: Hot reload enabled with volume mounts

### Testing Runtime

```bash
# Check runtime health
curl http://localhost:3003/api/health

# Execute code (requires auth in production)
curl -X POST http://localhost:3003/api/execute \
  -H "Content-Type: application/json" \
  -d '{"language": "python", "code": "print(\"Hello from Hanzo Runtime!\")"}'
```

## Service Communication

All services communicate through the internal Docker network:

- Chat → LLM Gateway: `http://llm-gateway:4000`
- Chat → Runtime: `http://runtime:3000`
- Services → All: Orchestration via service URLs
- All → PostgreSQL: `postgres:5432`
- All → Redis: `redis:6379`

## Development Workflow

### 1. Start Infrastructure
```bash
# Start only infrastructure services
docker compose up postgres redis mongodb minio meilisearch -d
```

### 2. Run Services Locally
```bash
# Run chat with hot reload
cd ../chat && npm run dev

# Run runtime with hot reload
cd ../runtime && npm run dev
```

### 3. Mixed Mode
```bash
# Infrastructure + some services in Docker, others locally
docker compose -f docker-compose.yaml -f compose.dev.yml up postgres redis llm-gateway
```

## Troubleshooting

### Port Conflicts
```bash
# Check what's using a port
lsof -i :3081

# Use custom ports
CHAT_PORT=3082 docker compose up
```

### Reset Everything
```bash
# Stop and remove all containers/volumes
docker compose down -v

# Clean Docker system
docker system prune -a
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f chat

# Last 100 lines
docker compose logs --tail=100 chat
```

## Production Deployment

For production:

1. Use strong passwords in environment variables
2. Enable TLS/SSL for external endpoints
3. Configure proper backup strategies
4. Use managed databases when possible
5. Set up monitoring and alerting

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Chat     │────▶│ LLM Gateway │────▶│  LLM APIs   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                                         
       ▼                                         
┌─────────────┐     ┌─────────────┐              
│   Runtime   │     │  Services   │              
└─────────────┘     └─────────────┘              
       │                    │                     
       ▼                    ▼                     
┌─────────────────────────────────────┐          
│  Infrastructure (DB, Redis, S3)     │          
└─────────────────────────────────────┘          
```

## Contributing

1. Clone the repository
2. Create a feature branch
3. Make your changes
4. Test with both production and development compose files
5. Submit a pull request

## License

See LICENSE file in the repository root.