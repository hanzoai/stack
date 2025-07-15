#!/bin/bash

# Basic test without Docker Compose
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

echo "Hanzo Stack Basic Test"
echo "====================="

# Test 1: Check Docker
if docker info >/dev/null 2>&1; then
    log "Docker is running"
else
    error "Docker is not running"
    exit 1
fi

# Test 2: Start PostgreSQL
echo ""
echo "Starting PostgreSQL..."
docker run -d --name test-postgres \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    -e POSTGRES_DB=test \
    -p 5432:5432 \
    postgres:16-alpine

sleep 5

if docker exec test-postgres pg_isready -U test >/dev/null 2>&1; then
    log "PostgreSQL started successfully"
else
    error "PostgreSQL failed to start"
fi

# Test 3: Start Redis
echo ""
echo "Starting Redis..."
docker run -d --name test-redis \
    -p 6379:6379 \
    redis:7-alpine redis-server --requirepass test123

sleep 3

if docker exec test-redis redis-cli -a test123 ping | grep -q PONG; then
    log "Redis started successfully"
else
    error "Redis failed to start"
fi

# Test 4: Start LiteLLM
echo ""
echo "Starting LiteLLM..."
docker run -d --name test-litellm \
    -p 4000:4000 \
    -e LITELLM_MASTER_KEY=sk-test \
    -e LITELLM_MODE=PRODUCTION \
    ghcr.io/berriai/litellm:main-stable \
    --test --port 4000

sleep 10

if curl -sf http://localhost:4000/health >/dev/null; then
    log "LiteLLM started successfully"
else
    error "LiteLLM failed to start"
    docker logs test-litellm
fi

# Test 5: Test LLM functionality
echo ""
echo "Testing LLM functionality..."
response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer sk-test" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Hi"}],
        "mock_response": "Hello! This is a test response."
    }' 2>/dev/null || echo "{}")

if echo "$response" | grep -q "choices"; then
    log "LLM chat completion works"
else
    error "LLM chat completion failed"
    echo "Response: $response"
fi

# Cleanup
echo ""
echo "Cleaning up..."
docker stop test-postgres test-redis test-litellm >/dev/null 2>&1
docker rm test-postgres test-redis test-litellm >/dev/null 2>&1

echo ""
echo "Basic test completed!"