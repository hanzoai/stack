# Hanzo Stack Build Status

## Current State

The Hanzo Stack is configured to use Docker images from GitHub Container Registry (ghcr.io/hanzoai), but these images need to be built and pushed first.

## Available Commands

### Infrastructure Only
```bash
make infra
```
This starts only the infrastructure services (PostgreSQL, Redis, MongoDB, MinIO, Meilisearch) which are available from Docker Hub.

### Development Mode
```bash
make dev
```
This builds services from local source code (requires ../llm, ../chat, etc. directories).

### Production Mode
```bash
make up
```
This will work once images are pushed to ghcr.io/hanzoai/*.

## Required Actions

1. **Build and push Docker images** for each service:
   ```bash
   cd ../router && docker build -t ghcr.io/hanzoai/router:latest . && docker push ghcr.io/hanzoai/router:latest
   cd ../chat && docker build -t ghcr.io/hanzoai/chat:latest . && docker push ghcr.io/hanzoai/chat:latest
   # etc...
   ```

2. **Use development mode** for now:
   ```bash
   make dev
   ```

3. **Or use infrastructure only**:
   ```bash
   make infra
   ```

## Service Status

- ✅ Infrastructure (postgres, redis, mongodb, minio, meilisearch)
- ❌ Router (needs ghcr.io/hanzoai/router:latest)
- ❌ Chat (needs ghcr.io/hanzoai/chat:latest)
- ❌ Analytics (needs ghcr.io/hanzoai/analytics:latest)
- ❌ IDE (needs ghcr.io/hanzoai/ide:latest)
- ❌ Runtime (needs ghcr.io/hanzoai/runtime:latest)
- ❌ IAM (needs ghcr.io/hanzoai/iam:latest)
- ❌ Search (needs ghcr.io/hanzoai/search:latest)
- ❌ Cloud (needs ghcr.io/hanzoai/cloud:latest)
- ❌ Agent (needs ghcr.io/hanzoai/agent:latest)
- ❌ Flow (needs ghcr.io/hanzoai/flow:latest)
- ❌ API (needs ghcr.io/hanzoai/api:latest)
