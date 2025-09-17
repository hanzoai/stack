# Hanzo Stack Service Fixes

## Issues Identified and Fixed

### 1. Port Conflicts (RESOLVED)
- **Issue**: Multiple services conflicting on ports 5432, 6379, 9000, 9001
- **Solution**: Created `docker-compose.override.yml` with port remapping:
  - PostgreSQL: 5432 → 5433
  - Redis: 6379 → 6380
  - MinIO: 9000 → 9002, 9001 → 9003
- **Status**: ✅ Working

### 2. MCP Server Name Configuration (FIXED)
- **Issue**: Router service failing with "Server name cannot contain '-'" error
- **Solution**: Changed `hanzo-mcp` to `hanzo_mcp` in router-config.yaml
- **File**: config/router-config.yaml line 118
- **Status**: ✅ Fixed in config

### 3. Nginx Configuration (FIXED)
- **Issue**: nginx.conf and nginx-default.conf were directories instead of files
- **Solution**: Created proper nginx configuration files
- **Files**: config/nginx.conf, config/nginx-default.conf
- **Status**: ✅ Fixed

### 4. Service Startup Issues
- **Chat Service**: Missing "backend" npm script - needs investigation
- **IDE/Analytics/IAM**: Platform mismatch (ARM64 images on AMD64 host)
- **Runtime**: Platform mismatch issue

## Working Services

✅ **Successfully Running:**
- MongoDB (port 27017)
- Meilisearch (port 7700)
- MinIO (ports 9002/9003)

⚠️ **Partially Working:**
- PostgreSQL (needs port 5433)
- Redis (needs port 6380)
- Router (config fixed, needs container rebuild)

❌ **Not Working:**
- Chat (missing npm script)
- IDE, Analytics, IAM, Runtime (platform issues)

## Test Results Summary

- **Tests Passing**: 28/67 (42%)
- **Tests Failing**: 39/67 (58%)
- **Main Issues**: Service connectivity due to port conflicts and platform mismatches

## Recommendations

1. **Immediate Actions:**
   - Use provided docker-compose.override.yml for local development
   - Stop conflicting services before starting Hanzo Stack
   - Use environment variables to override ports when needed

2. **Long-term Fixes:**
   - Build multi-platform images (AMD64 and ARM64)
   - Fix Chat service npm scripts
   - Consider using Docker network isolation instead of host ports

3. **Development Workflow:**
   ```bash
   # Stop conflicting services
   docker stop ai-platform-redis-1 ai-platform-clickhouse-1

   # Start with port overrides
   export POSTGRES_PORT=5433 REDIS_PORT=6380 MINIO_PORT=9002
   docker compose up -d
   ```

## Files Modified

1. `docker-compose.override.yml` - Port remapping
2. `config/router-config.yaml` - MCP server name fix
3. `config/nginx.conf` - Nginx configuration
4. `config/nginx-default.conf` - Default nginx config
5. `.env` - Updated port configurations
6. `CLAUDE.md` - Improved documentation
7. `PORT_CONFLICT_FIX.md` - Port conflict resolution guide

## Next Steps

1. Submit PR for multi-platform image builds
2. Fix Chat service startup script
3. Add health check improvements
4. Consider Kubernetes deployment for better isolation