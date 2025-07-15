#!/bin/bash

# Run Complete Hanzo Stack
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to stop all services
stop_all() {
    log "Stopping all Hanzo services..."
    
    # Kill any running Python services
    pkill -f "mock-llm-router.py" 2>/dev/null || true
    pkill -f "mock-api.py" 2>/dev/null || true
    pkill -f "llm.proxy.proxy_server" 2>/dev/null || true
    
    # Stop Docker containers
    docker stop hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch hanzo-clickhouse 2>/dev/null || true
    docker rm hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch hanzo-clickhouse 2>/dev/null || true
    
    log "All services stopped"
}

# Parse command line arguments
case "$1" in
    stop)
        stop_all
        exit 0
        ;;
    restart)
        stop_all
        sleep 5
        ;;
esac

log "Starting Complete Hanzo Stack"
log "============================="

# Step 1: Start Infrastructure
log "Starting infrastructure services..."

# PostgreSQL
if ! docker ps | grep -q hanzo-postgres; then
    docker run -d --name hanzo-postgres \
        -e POSTGRES_USER=hanzo \
        -e POSTGRES_PASSWORD=hanzo123 \
        -e POSTGRES_DB=hanzo \
        -p 5432:5432 \
        postgres:16-alpine
    info "Started PostgreSQL"
else
    info "PostgreSQL already running"
fi

# Redis
if ! docker ps | grep -q hanzo-redis; then
    docker run -d --name hanzo-redis \
        -p 6379:6379 \
        redis:7-alpine redis-server --requirepass hanzo123
    info "Started Redis"
else
    info "Redis already running"
fi

# MongoDB
if ! docker ps | grep -q hanzo-mongodb; then
    docker run -d --name hanzo-mongodb \
        -e MONGO_INITDB_ROOT_USERNAME=hanzo \
        -e MONGO_INITDB_ROOT_PASSWORD=hanzo123 \
        -e MONGO_INITDB_DATABASE=hanzo \
        -p 27017:27017 \
        mongo:7
    info "Started MongoDB"
else
    info "MongoDB already running"
fi

# MinIO
if ! docker ps | grep -q hanzo-minio; then
    docker run -d --name hanzo-minio \
        -p 9000:9000 -p 9001:9001 \
        -e MINIO_ROOT_USER=minioadmin \
        -e MINIO_ROOT_PASSWORD=minioadmin \
        minio/minio server /data --console-address ":9001"
    info "Started MinIO"
else
    info "MinIO already running"
fi

# Meilisearch
if ! docker ps | grep -q hanzo-meilisearch; then
    docker run -d --name hanzo-meilisearch \
        -p 7700:7700 \
        -e MEILI_MASTER_KEY=hanzo123 \
        -e MEILI_ENV=development \
        getmeili/meilisearch:latest
    info "Started Meilisearch"
else
    info "Meilisearch already running"
fi

# Wait for infrastructure
log "Waiting for infrastructure to be ready..."
sleep 15

# Verify infrastructure
INFRA_OK=true
docker exec hanzo-postgres pg_isready -U hanzo &>/dev/null && log "✓ PostgreSQL ready" || INFRA_OK=false
docker exec hanzo-redis redis-cli -a hanzo123 ping | grep -q PONG && log "✓ Redis ready" || INFRA_OK=false
docker exec hanzo-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null && log "✓ MongoDB ready" || INFRA_OK=false
curl -sf http://localhost:9000/minio/health/live >/dev/null && log "✓ MinIO ready" || INFRA_OK=false
curl -sf http://localhost:7700/health >/dev/null && log "✓ Meilisearch ready" || INFRA_OK=false

if [ "$INFRA_OK" = false ]; then
    error "Some infrastructure services failed to start"
    exit 1
fi

# Step 2: Start Hanzo Services
log "Starting Hanzo services..."

# Run the integration test script which starts mock services
/Users/z/work/hanzo/stack/run-integration-test.sh

# Display summary
echo ""
echo "========================================"
log "Hanzo Stack is Running!"
echo "========================================"
echo ""
echo "Infrastructure Services:"
echo "  PostgreSQL:  localhost:5432 (hanzo/hanzo123)"
echo "  Redis:       localhost:6379 (password: hanzo123)"
echo "  MongoDB:     localhost:27017 (hanzo/hanzo123)"
echo "  MinIO:       http://localhost:9001 (minioadmin/minioadmin)"
echo "  Meilisearch: http://localhost:7700 (key: hanzo123)"
echo ""
echo "Hanzo Services:"
echo "  LLM Router:  http://localhost:4000 (Hanzo AI Gateway)"
echo "  API:         http://localhost:8000 (Core API)"
echo ""
echo "Commands:"
echo "  $0 stop     - Stop all services"
echo "  $0 restart  - Restart all services"
echo ""
log "Press Ctrl+C to keep services running in background"