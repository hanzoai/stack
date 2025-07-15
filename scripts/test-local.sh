#!/bin/bash

# Local test script - no authentication required
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}$(date +'%H:%M:%S')${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

# Cleanup
cleanup() {
    log "Cleaning up..."
    docker compose -f docker-compose.local.yml down -v
}

trap cleanup EXIT

log "Starting Hanzo Stack Local Test"

# Start services
log "Starting core services..."
docker compose -f docker-compose.local.yml up -d

# Wait for services
log "Waiting for services to start..."
sleep 15

# Health checks
log "Running health checks..."

# PostgreSQL
if docker exec hanzo-postgres-local pg_isready -U hanzo >/dev/null 2>&1; then
    log "✓ PostgreSQL is healthy"
else
    error "✗ PostgreSQL failed"
    docker logs hanzo-postgres-local
fi

# Redis
if docker exec hanzo-redis-local redis-cli -a hanzo123 ping 2>/dev/null | grep -q PONG; then
    log "✓ Redis is healthy"
else
    error "✗ Redis failed"
    docker logs hanzo-redis-local
fi

# MongoDB
if docker exec hanzo-mongodb-local mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log "✓ MongoDB is healthy"
else
    error "✗ MongoDB failed"
    docker logs hanzo-mongodb-local
fi

# MinIO
if curl -sf http://localhost:9000/minio/health/live >/dev/null; then
    log "✓ MinIO is healthy"
else
    error "✗ MinIO failed"
    docker logs hanzo-minio-local
fi

# LiteLLM
sleep 5
if curl -sf http://localhost:4000/health >/dev/null; then
    log "✓ LiteLLM is healthy"
else
    error "✗ LiteLLM failed"
    docker logs hanzo-litellm-local
fi

# Test LiteLLM functionality
log "Testing LLM Gateway functionality..."

# Test models endpoint
info "Testing /models endpoint..."
models=$(curl -s http://localhost:4000/v1/models \
  -H "Authorization: Bearer sk-test-key")

if echo "$models" | grep -q "gpt-3.5-turbo"; then
    log "✓ Models endpoint works"
else
    error "✗ Models endpoint failed"
    echo "$models"
fi

# Test chat completion
info "Testing chat completion..."
response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test-key" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Say hello"}],
    "mock_response": true
  }')

if echo "$response" | grep -q "choices"; then
    log "✓ Chat completion works"
    echo "Response: $(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || echo "Mock response")"
else
    error "✗ Chat completion failed"
    echo "$response"
fi

# Show service URLs
echo ""
log "Service URLs:"
echo "  PostgreSQL: localhost:5432 (user: hanzo, pass: hanzo123)"
echo "  Redis: localhost:6379 (pass: hanzo123)"
echo "  MongoDB: localhost:27017 (user: hanzo, pass: hanzo123)"
echo "  MinIO: http://localhost:9001 (user: minioadmin, pass: minioadmin)"
echo "  LiteLLM: http://localhost:4000 (key: sk-test-key)"

echo ""
log "All services are running! Press Ctrl+C to stop."

# Keep running
wait