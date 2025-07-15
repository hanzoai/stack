#!/bin/bash

# Test Hanzo Stack with Hanzo services only
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
HANZO_REGISTRY="ghcr.io/hanzoai"
HANZO_VERSION="${HANZO_VERSION:-latest}"

# Cleanup function
cleanup() {
    log "Cleaning up Hanzo services..."
    docker compose -f docker-compose.hanzo.yml down -v 2>/dev/null || true
}

trap cleanup EXIT

log "Starting Hanzo Stack Test (Hanzo Services Only)"
log "==============================================="

# Create Hanzo-specific compose file
cat > docker-compose.hanzo.yml << EOF
# Hanzo Stack - Using only Hanzo services
services:
  # Core Infrastructure (standard images for data storage)
  postgres:
    image: postgres:16-alpine
    container_name: hanzo-postgres
    environment:
      - POSTGRES_USER=hanzo
      - POSTGRES_PASSWORD=hanzo123
      - POSTGRES_DB=hanzo
    ports:
      - "5432:5432"
    networks:
      - hanzo
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hanzo"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: hanzo-redis
    command: redis-server --requirepass hanzo123
    ports:
      - "6379:6379"
    networks:
      - hanzo
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "hanzo123", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  mongodb:
    image: mongo:7
    container_name: hanzo-mongodb
    environment:
      - MONGO_INITDB_ROOT_USERNAME=hanzo
      - MONGO_INITDB_ROOT_PASSWORD=hanzo123
      - MONGO_INITDB_DATABASE=hanzo
    ports:
      - "27017:27017"
    networks:
      - hanzo

  minio:
    image: minio/minio:latest
    container_name: hanzo-minio
    command: server /data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      - hanzo

  # Hanzo LLM Gateway (our fork)
  llm-router:
    image: ${HANZO_REGISTRY}/llm:${HANZO_VERSION}
    container_name: hanzo-llm-router
    environment:
      - PORT=4000
      - DATABASE_URL=postgresql://hanzo:hanzo123@postgres:5432/hanzo
      - REDIS_URL=redis://:hanzo123@redis:6379
      - MASTER_KEY=sk-hanzo-test
      - MOCK_MODE=true
      - LOG_LEVEL=debug
    ports:
      - "4000:4000"
    networks:
      - hanzo
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 10s
      timeout: 5s
      retries: 10

  # Hanzo API Service
  api:
    image: ${HANZO_REGISTRY}/api:${HANZO_VERSION}
    container_name: hanzo-api
    environment:
      - PORT=8000
      - DATABASE_URL=postgresql://hanzo:hanzo123@postgres:5432/hanzo
      - REDIS_URL=redis://:hanzo123@redis:6379
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=minioadmin
      - MINIO_SECRET_KEY=minioadmin
      - MINIO_USE_SSL=false
      - AUTH_SECRET=test-secret
    ports:
      - "8000:8000"
    networks:
      - hanzo
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      timeout: 5s
      retries: 10

  # Hanzo Chat Service
  chat:
    image: ${HANZO_REGISTRY}/chat:${HANZO_VERSION}
    container_name: hanzo-chat
    environment:
      - PORT=3081
      - DATABASE_URL=mongodb://hanzo:hanzo123@mongodb:27017/chat?authSource=admin
      - REDIS_URL=redis://:hanzo123@redis:6379
      - LLM_GATEWAY_URL=http://llm-router:4000
      - NEXTAUTH_URL=http://localhost:3081
      - NEXTAUTH_SECRET=test-secret
    ports:
      - "3081:3081"
    networks:
      - hanzo
    depends_on:
      - mongodb
      - redis
      - llm-router

  # Hanzo Search Service
  search:
    image: ${HANZO_REGISTRY}/search:${HANZO_VERSION}
    container_name: hanzo-search
    environment:
      - PORT=3000
      - DATABASE_URL=postgresql://hanzo:hanzo123@postgres:5432/hanzo
      - MEILISEARCH_URL=http://meilisearch:7700
      - MEILISEARCH_KEY=hanzo123
    ports:
      - "3000:3000"
    networks:
      - hanzo
    depends_on:
      - postgres

  # Meilisearch (for search service)
  meilisearch:
    image: getmeili/meilisearch:latest
    container_name: hanzo-meilisearch
    environment:
      - MEILI_MASTER_KEY=hanzo123
      - MEILI_ENV=development
    ports:
      - "7700:7700"
    networks:
      - hanzo

networks:
  hanzo:
    driver: bridge
    name: hanzo-network

volumes:
  postgres_data:
  redis_data:
  mongodb_data:
  minio_data:
  meilisearch_data:
EOF

# Start services
log "Starting Hanzo services..."
docker compose -f docker-compose.hanzo.yml up -d postgres redis mongodb minio meilisearch

# Wait for infrastructure
log "Waiting for infrastructure services..."
sleep 15

# Check infrastructure health
info "Checking infrastructure services..."
docker compose -f docker-compose.hanzo.yml ps

# Start Hanzo services
log "Starting Hanzo application services..."
docker compose -f docker-compose.hanzo.yml up -d llm-router api chat search

# Wait for Hanzo services
log "Waiting for Hanzo services to initialize..."
sleep 20

# Health checks
log "Running health checks..."

# Check LLM Router
if curl -sf http://localhost:4000/health >/dev/null; then
    log "✓ Hanzo LLM Router is healthy"
    
    # Test LLM functionality
    response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-hanzo-test" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello from Hanzo"}]
        }')
    
    if echo "$response" | grep -q "choices"; then
        log "✓ LLM Router chat completion works"
    else
        error "✗ LLM Router chat completion failed"
        echo "$response"
    fi
else
    error "✗ Hanzo LLM Router failed"
    docker logs hanzo-llm-router
fi

# Check API
if curl -sf http://localhost:8000/health >/dev/null; then
    log "✓ Hanzo API is healthy"
else
    error "✗ Hanzo API failed"
    docker logs hanzo-api
fi

# Check Chat
if curl -sf http://localhost:3081/api/health >/dev/null; then
    log "✓ Hanzo Chat is healthy"
else
    error "✗ Hanzo Chat failed"
    docker logs hanzo-chat
fi

# Check Search
if curl -sf http://localhost:3000 >/dev/null; then
    log "✓ Hanzo Search is healthy"
else
    error "✗ Hanzo Search failed"
    docker logs hanzo-search
fi

# Run integration tests
log "Running integration tests..."

# Test 1: Create project via API
info "Test 1: Creating project..."
project_response=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d '{
        "name": "Integration Test Project",
        "description": "Testing Hanzo Stack"
    }')

if echo "$project_response" | grep -q "id"; then
    log "✓ Project creation successful"
    PROJECT_ID=$(echo "$project_response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
else
    error "✗ Project creation failed"
    echo "$project_response"
fi

# Test 2: Create trace
info "Test 2: Creating trace..."
trace_response=$(curl -s -X POST http://localhost:8000/api/v1/traces \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d "{
        \"project_id\": \"$PROJECT_ID\",
        \"name\": \"test-trace\",
        \"input\": {\"query\": \"test\"},
        \"output\": {\"response\": \"test response\"}
    }")

if echo "$trace_response" | grep -q "id"; then
    log "✓ Trace creation successful"
else
    error "✗ Trace creation failed"
    echo "$trace_response"
fi

# Test 3: Chat conversation
info "Test 3: Testing chat..."
# Note: Chat may require authentication setup, so we just test the endpoint
chat_health=$(curl -s http://localhost:3081/api/health)
if echo "$chat_health" | grep -q "ok\|healthy"; then
    log "✓ Chat service functional"
else
    error "✗ Chat service not functional"
fi

# Show service URLs
echo ""
log "Hanzo Stack is running!"
echo ""
echo "Service URLs:"
echo "  LLM Router:  http://localhost:4000"
echo "  API:         http://localhost:8000"
echo "  Chat:        http://localhost:3081"
echo "  Search:      http://localhost:3000"
echo "  MinIO:       http://localhost:9001 (minioadmin/minioadmin)"
echo ""
echo "API Documentation:"
echo "  LLM Router:  http://localhost:4000/docs"
echo "  API:         http://localhost:8000/docs"
echo ""
log "Press Ctrl+C to stop all services"

# Keep running
wait