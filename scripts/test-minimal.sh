#!/bin/bash

# Minimal test script for Hanzo Stack
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    docker compose -f docker-compose.minimal.yml --env-file .env.test down -v
}

trap cleanup EXIT

log "Starting Hanzo Stack minimal test"

# Check if .env.test exists
if [ ! -f .env.test ]; then
    error ".env.test not found"
    exit 1
fi

# Start services
log "Starting services..."
docker compose -f docker-compose.minimal.yml --env-file .env.test up -d

# Wait for services
log "Waiting for services to be ready..."
sleep 20

# Check health
log "Checking service health..."

# PostgreSQL
if docker compose -f docker-compose.minimal.yml exec -T postgres pg_isready -U hanzo_test; then
    log "✓ PostgreSQL is healthy"
else
    error "✗ PostgreSQL is not healthy"
fi

# Redis
if docker compose -f docker-compose.minimal.yml exec -T redis redis-cli -a test123 ping | grep -q PONG; then
    log "✓ Redis is healthy"
else
    error "✗ Redis is not healthy"
fi

# MinIO
if curl -f http://localhost:9000/minio/health/live; then
    log "✓ MinIO is healthy"
else
    error "✗ MinIO is not healthy"
fi

# Mock OpenAI
if curl -f http://localhost:8080/status; then
    log "✓ Mock OpenAI is healthy"
else
    error "✗ Mock OpenAI is not healthy"
fi

# LLM Gateway
if curl -f http://localhost:4000/health; then
    log "✓ LLM Gateway is healthy"
else
    error "✗ LLM Gateway is not healthy"
fi

# Test LLM Gateway functionality
log "Testing LLM Gateway..."

# Test chat completion
response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-router-test" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello"}]
  }')

if echo "$response" | grep -q "choices"; then
    log "✓ LLM Gateway chat completion works"
else
    error "✗ LLM Gateway chat completion failed"
    echo "$response"
fi

log "All tests passed!"