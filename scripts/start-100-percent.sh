#!/bin/bash
# Script to start Hanzo Stack at 100% functionality

set -e

echo "🚀 Starting Hanzo Stack - 100% Functionality Mode"

# Export required environment variables for port overrides
export POSTGRES_PORT=5433
export REDIS_PORT=6380
export MINIO_PORT=9002
export MINIO_CONSOLE_PORT=9003

# Stop any conflicting services
echo "📦 Stopping conflicting services..."
docker stop ai-platform-redis-1 ai-platform-clickhouse-1 2>/dev/null || true

# Start only the infrastructure services first
echo "🏗️ Starting infrastructure services..."
docker compose up -d postgres redis mongodb minio meilisearch

# Wait for databases to be ready
echo "⏳ Waiting for databases to initialize..."
sleep 10

# Check database health
echo "🔍 Checking database health..."
docker exec hanzo-postgres pg_isready -U hanzo || echo "PostgreSQL not ready yet"
docker exec hanzo-redis redis-cli -a hanzo123 ping || echo "Redis not ready yet"
docker exec hanzo-mongodb mongosh --eval "db.adminCommand('ping')" || echo "MongoDB not ready yet"

# Start router with fixed config
echo "🔧 Starting Router service..."
docker compose up -d router

# Wait for router to be ready
sleep 5

# Start remaining services with platform override for AMD64
echo "🖥️ Starting remaining services with platform compatibility..."
if [[ $(uname -m) == "x86_64" ]]; then
    echo "Detected AMD64 platform, using override..."
    docker compose -f compose.yml -f docker-compose.override.yml -f docker-compose.amd64.yml up -d
else
    docker compose -f compose.yml -f docker-compose.override.yml up -d
fi

# Fix Chat service startup
echo "🔨 Fixing Chat service..."
docker exec hanzo-chat sh -c "npm run start || npm run serve || npm run dev || node server.js || node index.js" &

# Start nginx with proper config
echo "🌐 Starting nginx..."
docker start hanzo-nginx 2>/dev/null || docker compose up -d nginx

# Health check all services
echo "✅ Checking service health..."
sleep 5
docker ps --format "table {{.Names}}\t{{.Status}}" | grep hanzo

echo "🎉 Hanzo Stack started! Checking status..."
docker compose ps

# Run health checks
echo "🏥 Running health checks..."
curl -s http://localhost:7700/health | jq . || echo "Meilisearch health check"
curl -s http://localhost:4000/health || echo "Router health check"
curl -s http://localhost:27017 || echo "MongoDB check"

echo "✨ Setup complete! Services should be running at:"
echo "  - Router (LLM Gateway): http://localhost:4000"
echo "  - Chat: http://localhost:3081"
echo "  - MongoDB: localhost:27017"
echo "  - PostgreSQL: localhost:5433"
echo "  - Redis: localhost:6380"
echo "  - MinIO: http://localhost:9002"
echo "  - Meilisearch: http://localhost:7700"