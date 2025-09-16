# Hanzo AI Services - Docker Deployment Guide

This guide covers the production-ready Docker deployment for the core Hanzo AI services: Runtime, Cloud, and MCP.

## 🚀 Quick Start

```bash
# Clone and navigate to the stack directory
cd /Users/z/work/hanzo/stack

# Start all services
docker compose -f compose.yml up -d

# Check service status
docker compose -f compose.yml ps

# View logs
docker compose -f compose.yml logs -f
```

## 📋 Services Overview

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| hanzo-runtime | 3000 | Node.js/NestJS runtime service | `/health` |
| hanzo-cloud | 3001 | Next.js cloud dashboard | `/api/health` |
| hanzo-mcp | N/A | TypeScript MCP server | Process check |
| postgres | 5432 | PostgreSQL database | `pg_isready` |
| redis | 6379 | Redis cache | `ping` |
| traefik | 80/443/8080 | Reverse proxy & SSL | Auto |

## 🏗️ Architecture Features

### Multi-Stage Builds
- **Base Stage**: Common dependencies and security updates
- **Dependencies Stage**: Install and cache dependencies
- **Builder Stage**: Compile and build applications
- **Development Stage**: Hot-reload development environment
- **Production Stage**: Minimal runtime with only necessary files

### Security Best Practices
- ✅ Non-root user execution
- ✅ Minimal Alpine Linux base images
- ✅ Security updates in base layers
- ✅ Proper signal handling with tini
- ✅ Comprehensive .dockerignore files
- ✅ Health checks for all services

### Optimization Features
- ✅ Layer caching for faster builds
- ✅ Multi-stage builds for smaller images
- ✅ Production dependency pruning
- ✅ Efficient COPY ordering
- ✅ Build context optimization

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the stack directory:

```bash
# Database Configuration
POSTGRES_DB=hanzo
POSTGRES_USER=hanzo_user
POSTGRES_PASSWORD=secure_password
DATABASE_URL=postgresql://hanzo_user:secure_password@postgres:5432/hanzo

# Redis Configuration
REDIS_PASSWORD=redis_password
REDIS_URL=redis://:redis_password@redis:6379

# Authentication
NEXTAUTH_URL=https://cloud.hanzo.ai
NEXTAUTH_SECRET=your-super-secret-key

# SSL/TLS
DOMAIN=hanzo.ai
ACME_EMAIL=admin@hanzo.ai

# Ports (optional overrides)
POSTGRES_PORT=5432
REDIS_PORT=6379
```

## 🚀 Deployment Options

### Development

```bash
# Build and start from local submodules
make submodules-ensure
docker compose -f compose.dev.yml up -d --build
```

### Production

```bash
# Start production stack using published images
docker compose -f compose.yml up -d
```

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
name: Build and Deploy Hanzo Services

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Runtime
        run: |
          docker build --target production -t hanzoai/runtime:${{ github.sha }} runtime/
          docker tag hanzoai/runtime:${{ github.sha }} hanzoai/runtime:latest
      
      - name: Build Cloud
        run: |
          docker build --target production -t hanzoai/cloud:${{ github.sha }} cloud/
          docker tag hanzoai/cloud:${{ github.sha }} hanzoai/cloud:latest
      
      - name: Build MCP
        run: |
          docker build --target production -t hanzoai/mcp:${{ github.sha }} mcp/
          docker tag hanzoai/mcp:${{ github.sha }} hanzoai/mcp:latest
      
      - name: Push to Registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push hanzoai/runtime:${{ github.sha }}
          docker push hanzoai/runtime:latest
          docker push hanzoai/cloud:${{ github.sha }}
          docker push hanzoai/cloud:latest
          docker push hanzoai/mcp:${{ github.sha }}
          docker push hanzoai/mcp:latest
```

## 📊 Monitoring & Health Checks

### Service Health Status

```bash
# Check all service health
docker compose -f compose.yml ps

# Individual service health
docker inspect --format='{{.State.Health.Status}}' hanzo-runtime
docker inspect --format='{{.State.Health.Status}}' hanzo-cloud

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' hanzo-runtime
```

### Resource Monitoring

```bash
# Container resource usage
docker stats hanzo-runtime hanzo-cloud hanzo-mcp

# Disk usage
docker system df

# Clean up unused resources
docker system prune -af --volumes
```

## 🔍 Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :3000
   
   # Use different ports
   docker compose -f compose.yml up -d \
     -e "POSTGRES_PORT=5433" \
     -e "REDIS_PORT=6380"
   ```

2. **Build Failures**
   ```bash
   # Build with no cache
   docker build --no-cache --target production -t hanzoai/runtime:latest runtime/
   
   # Check build context size
   docker build --target production --progress=plain runtime/
   ```

3. **Permission Issues**
   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER runtime/ cloud/ mcp/
   
   # Check Docker daemon
   sudo systemctl status docker
   ```

4. **Memory Issues**
   ```bash
   # Increase Docker memory limit
   # Docker Desktop: Settings > Resources > Memory
   
   # Add memory limits to compose
   deploy:
     resources:
       limits:
         memory: 512M
   ```

### Debugging Commands

```bash
# Enter running container
docker exec -it hanzo-runtime /bin/sh

# View container logs
docker logs -f hanzo-runtime

# Inspect container configuration
docker inspect hanzo-runtime

# Check network connectivity
docker exec hanzo-runtime ping postgres
docker exec hanzo-runtime ping redis
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] Use strong, unique passwords for all services
- [ ] Enable SSL/TLS with valid certificates
- [ ] Implement proper firewall rules
- [ ] Regular security updates for base images
- [ ] Scan images for vulnerabilities
- [ ] Use secrets management for sensitive data
- [ ] Enable audit logging
- [ ] Implement backup strategies

### Vulnerability Scanning

```bash
# Scan images for vulnerabilities
docker scout cves hanzoai/runtime:latest
docker scout cves hanzoai/cloud:latest
docker scout cves hanzoai/mcp:latest

# Using Trivy
trivy image hanzoai/runtime:latest
trivy image hanzoai/cloud:latest
trivy image hanzoai/mcp:latest
```

## 📈 Performance Optimization

### Build Optimization

1. **Multi-stage builds** - Reduce final image size
2. **Layer caching** - Optimize build order
3. **Dependency caching** - Cache package installs
4. **Build context** - Minimize context size with .dockerignore

### Runtime Optimization

1. **Resource limits** - Set appropriate CPU/memory limits
2. **Health checks** - Monitor service availability
3. **Logging** - Structured logging for observability
4. **Caching** - Redis for application caching

## 🆙 Updates and Maintenance

### Regular Maintenance

```bash
# Update base images
docker pull node:20-alpine
docker pull postgres:16-alpine
docker pull redis:7-alpine

# Rebuild with updated bases
docker compose -f compose.yml build --no-cache

# Update and restart services
docker compose -f compose.yml pull
docker compose -f compose.yml up -d
```

### Backup Procedures

```bash
# Backup PostgreSQL
docker exec hanzo-postgres pg_dump -U hanzo_user hanzo > backup.sql

# Backup Redis
docker exec hanzo-redis redis-cli BGSAVE
docker cp hanzo-redis:/data/dump.rdb ./redis-backup.rdb

# Backup volumes
docker run --rm -v hanzo-postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data
```

## 📚 Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Docker Compose Production](https://docs.docker.com/compose/production/)

---

For additional support, please refer to the individual service documentation or contact the Hanzo AI team.
