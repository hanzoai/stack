# Hanzo Stack

Complete development and production stack for Hanzo AI platform.

## Quick Start

### Production Mode (Using Pre-built Images)
```bash
# Start all services with pre-built images
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Development Mode (Building from Source)
```bash
# Start all services building from local source code
docker compose -f compose.dev.yml up -d

# View logs
docker compose -f compose.dev.yml logs -f

# Stop services
docker compose -f compose.dev.yml down
```

## Available Services

| Service | Production Port | Dev Port | Description |
|---------|----------------|----------|-------------|
| PostgreSQL | 5432 | 5432 | Primary database |
| Redis | 6379 | 6379 | Cache and message queue |
| MongoDB | 27017 | 27017 | Document database |
| MinIO | 9000/9001 | 9000/9001 | S3-compatible storage |
| Meilisearch | 7700 | 7700 | Search engine |
| Router | 4000 | 4000 | LLM Gateway |
| Chat | 3081 | 3081 | LibreChat fork with MCP support |
| IDE | 3002 | 3002 | OpenHands AI development assistant |
| Analytics | 3090 | 3090 | Privacy-focused analytics platform |
| Runtime | 8002 | 8002 | Code execution sandbox |
| Cloud | 3001 | 3001 | Infrastructure management (coming soon) |
| Search | 3000 | 3000 | AI-powered search (coming soon) |
| IAM | 8000 | 8000 | Identity management (coming soon) |

## Development Tools

Start additional development tools:
```bash
# Production mode
docker compose --profile tools up -d

# Development mode
docker compose -f compose.dev.yml --profile tools up -d
```

Tools available:
- Adminer (Database UI): http://localhost:8080
- Redis Commander: http://localhost:8081
- Mongo Express: http://localhost:8082

## Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:

```bash
# API Keys (required for Router)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Database Credentials (defaults provided)
POSTGRES_USER=hanzo
POSTGRES_PASSWORD=hanzo123

# Service Ports (defaults provided)
ROUTER_PORT=4000
CHAT_PORT=3081
```

### Router Configuration
- Production: Uses `config/router-config-minimal.yaml`
- Development: Uses `config/router-config.yaml` with full features

## File Structure

```
stack/
├── compose.yml              # Production compose with pre-built images
├── compose.dev.yml          # Development compose building from source
├── config/                  # Service configuration files
│   ├── router-config.yaml
│   └── router-config-minimal.yaml
├── data/                    # Persistent data (dev mode)
├── logs/                    # Service logs (dev mode)
└── tests/                   # Integration tests
```

## Testing

Run integration tests:
```bash
cd tests
npm install
npm test
```

## Troubleshooting

### Services not starting
```bash
# Check service logs
docker compose logs [service-name]

# Restart specific service
docker compose restart [service-name]

# Clean restart everything
docker compose down -v
docker compose up -d
```

### Port conflicts
```bash
# Check what's using a port
lsof -i :PORT_NUMBER

# Kill process using port
kill -9 PID
```

### Volume issues
```bash
# List volumes
docker volume ls | grep hanzo

# Remove specific volume
docker volume rm VOLUME_NAME

# Remove all Hanzo volumes (WARNING: deletes data)
docker compose down -v
```

## Production Deployment

For production deployment:

1. Use `compose.yml` (not `compose.dev.yml`)
2. Set proper environment variables in `.env`
3. Use real API keys for LLM providers
4. Configure proper database passwords
5. Set up SSL/TLS termination (use Traefik or nginx)
6. Enable backups for data volumes

## Development Workflow

1. Clone all required repositories alongside the stack:
   ```
   hanzo/
   ├── stack/      # This repository
   ├── llm/        # Router service
   ├── chat/       # Chat service
   ├── cloud/      # Cloud service
   ├── search/     # Search service
   ├── ide/        # IDE service
   ├── iam/        # IAM service
   └── runtime/    # Runtime service
   ```

2. Start development stack:
   ```bash
   cd stack
   docker compose -f compose.dev.yml up -d
   ```

3. Services will hot-reload when you edit source files

4. View logs for debugging:
   ```bash
   docker compose -f compose.dev.yml logs -f [service-name]
   ```

## License

See LICENSE file in the root directory.