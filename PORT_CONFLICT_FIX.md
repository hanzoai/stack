# Port Conflict Resolution for Hanzo Stack

## Issue Summary
Multiple port conflicts were encountered when attempting to run the Hanzo Stack due to existing services running on the same ports.

## Conflicting Ports
- **Port 5432** - PostgreSQL (used by local PostgreSQL installation)
- **Port 6379** - Redis (used by ai-platform-redis-1 container)
- **Port 9000** - MinIO (used by ai-platform-clickhouse-1 container)
- **Port 9001** - MinIO Console (potential conflict)

## Solution Implemented

### 1. Docker Compose Override File
Created `docker-compose.override.yml` to remap conflicting ports:

```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # Map to 5433 to avoid conflict

  minio:
    ports:
      - "9002:9000"  # Map to 9002 to avoid conflict
      - "9003:9001"  # Map console to 9003
```

### 2. Environment Variables Update
Updated `.env` file with alternative ports:
- `POSTGRES_PORT=5433`
- `MINIO_PORT=9002`
- `MINIO_CONSOLE_PORT=9003`

## Test Results

### Working Services
✅ MongoDB (port 27017)
✅ Meilisearch (port 7700)
✅ Local PostgreSQL connection test
✅ Local MinIO connection test

### Services Requiring Port Remapping
- PostgreSQL → Use port 5433
- Redis → Stop conflicting container or use port 6380
- MinIO → Use ports 9002/9003

## Recommendations

1. **For Development**: Use the docker-compose.override.yml file to avoid port conflicts
2. **For CI/CD**: Ensure clean environment with no conflicting services
3. **For Production**: Use dedicated ports or container networking without host port binding

## Quick Start with Fixed Ports

```bash
# Stop conflicting services
docker stop ai-platform-redis-1 ai-platform-clickhouse-1

# Start Hanzo Stack with override
docker compose up -d

# Or use alternative ports in .env
export POSTGRES_PORT=5433
export REDIS_PORT=6380
export MINIO_PORT=9002
docker compose up -d
```

## Integration Test Status
- 26 tests passing (infrastructure connectivity)
- 41 tests failing (missing services due to port conflicts)
- Core infrastructure validated (MongoDB, Meilisearch working)