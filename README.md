# Hanzo Stack

The complete Hanzo AI infrastructure stack - run all 50+ Hanzo services locally with a single command.

## Overview

This repository provides a unified way to run the entire Hanzo AI ecosystem locally for development and testing. It orchestrates all services including:

- Core AI Infrastructure (LLM, Chat, MCP, Agent, Operative)
- AI Models & Research (Jin, GPT, Enso, Genjo)
- Application Platforms (Search, Flow, Studio, Suite)
- Developer Tools (API, Cloud, KMS, IAM)
- Business & Finance (Financials, Captable)
- And 30+ more services

## Quick Start

```bash
# Clone this repository
git clone https://github.com/hanzoai/stack.git
cd stack

# Clone all Hanzo repositories
make clone-all

# Start the entire stack
make up

# Check service health
make health
```

## Prerequisites

- Docker and Docker Compose v2+
- At least 32GB RAM (64GB recommended)
- 100GB+ free disk space
- Python 3.11+ with uv
- Node.js 20+ with pnpm
- Go 1.21+

## Architecture

The stack is organized into logical groups:

### Core Services
- **PostgreSQL**: Primary database with pgvector
- **Redis**: Caching and queuing
- **MinIO**: S3-compatible object storage
- **MongoDB**: Document storage
- **Meilisearch**: Full-text search
- **ClickHouse**: Analytics database

### AI Infrastructure
- **LLM Gateway** (port 4000): Unified LLM proxy
- **Chat** (port 3081): AI chat platform
- **MCP**: Model Context Protocol server
- **Agent**: Multi-agent orchestration
- **Operative**: Computer use implementation

### Application Services
- **Search** (port 3000): AI-powered search
- **Flow**: Visual workflow builder
- **Studio**: Desktop application
- **Suite**: Business applications

### Supporting Services
- **API** (port 8000): Core API services
- **Cloud**: Infrastructure management
- **IAM**: Identity management
- **KMS**: Key management

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| LLM Gateway | 4000 | Unified LLM proxy |
| Chat | 3081 | AI chat platform |
| Search | 3000 | AI search engine |
| API | 8000 | Core API |
| Az2 Admin | 5173 | Document processing UI |
| Az2 API | 9002 | Document processing API |
| MinIO | 9000/9001 | Object storage |
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache/queue |
| MongoDB | 27017 | Document database |

## Commands

```bash
# Service management
make up              # Start all services
make down            # Stop all services
make restart         # Restart all services
make logs            # View all logs
make health          # Check service health

# Individual service groups
make up-core         # Start core infrastructure only
make up-ai           # Start AI services only
make up-apps         # Start application services only

# Development
make dev             # Start in development mode
make test            # Run all tests
make build           # Build all services

# Maintenance
make clean           # Clean containers and volumes
make reset           # Full reset (WARNING: deletes data)
make backup          # Backup all data
make restore         # Restore from backup
```

## Environment Configuration

Copy the example environment file and configure:

```bash
cp .env.example .env
```

Required environment variables:

```bash
# Database
POSTGRES_USER=hanzo
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=hanzo

# Redis
REDIS_PASSWORD=secure_password

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=secure_password

# AI Providers (at least one required)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
TOGETHER_API_KEY=...

# Authentication
CLERK_SECRET_KEY=...
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

## Memory Requirements

Minimum requirements by service group:

- Core Infrastructure: 8GB
- AI Services: 16GB
- Application Services: 8GB
- Full Stack: 32GB (64GB recommended)

## Monitoring

Access monitoring dashboards:

- Grafana: http://localhost:3030
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686

## Troubleshooting

### Out of Memory

Increase Docker memory allocation:
- Docker Desktop: Preferences > Resources > Memory

### Port Conflicts

Check and kill conflicting processes:
```bash
make check-ports
```

### Service Won't Start

Check individual service logs:
```bash
make logs service=chat
```

### Reset Individual Service

```bash
make reset-service service=chat
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

See individual service repositories for license information.