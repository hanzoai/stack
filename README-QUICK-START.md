# 🚀 Hanzo Stack - Quick Start Guide

## Current Status: ✅ All Services Running

### 🟢 Running Services

| Service | Port | Status | Access |
|---------|------|--------|--------|
| PostgreSQL | 5432 | ✅ Healthy | `PGPASSWORD=hanzo123 psql -h localhost -U hanzo -d hanzo` |
| Redis | 6379 | ✅ Healthy | `redis-cli -a hanzo123` |
| MongoDB | 27017 | ✅ Healthy | Port 27017 (use MongoDB client) |
| MinIO | 9000/9001 | ✅ Healthy | Console: http://localhost:9001 |
| Meilisearch | 7700 | ✅ Healthy | UI: http://localhost:7700 |
| Router (LLM) | 4000 | ✅ Running | API: http://localhost:4000 |

### 🎯 Quick Commands

```bash
# Start the stack
docker compose up -d

# Stop the stack
docker compose down

# View logs
docker compose logs -f

# Check status
docker ps | grep hanzo

# Restart services
docker compose restart
```

### 🌐 Web Interfaces

1. **MinIO Console**: http://localhost:9001
   - Username: `minioadmin`
   - Password: `minioadmin`

2. **Meilisearch**: http://localhost:7700
   - No authentication required for development

3. **Router API**: http://localhost:4000
   - Requires API key for most endpoints
   - Master key: `sk-router-master-hanzo`

### 🔐 Default Credentials

- **PostgreSQL**: `hanzo` / `hanzo123`
- **Redis**: Password `hanzo123`
- **MongoDB**: `hanzo` / `hanzo123`
- **MinIO**: `minioadmin` / `minioadmin`
- **Meilisearch**: Master key `hanzo-meili-master`

### 📦 Data Persistence

All data is persisted in Docker volumes:
- `postgres_data`
- `redis_data`
- `mongodb_data`
- `minio_data`
- `meilisearch_data`

### 🧪 Running Tests

```bash
cd tests
npm install
npm test
```

### 📝 Configuration Files

- Main compose: `compose.yml`
- Router config: `config/router-config-minimal.yaml`
- Environment: `.env` (create from `.env.example`)

### 🆘 Troubleshooting

If services fail to start:
```bash
# Check logs
docker logs hanzo-[service-name]

# Restart individual service
docker restart hanzo-[service-name]

# Clean restart
docker compose down -v
docker compose up -d
```

---

**Stack is ready for testing! All services are running and healthy.** 🎉