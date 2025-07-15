#!/bin/bash

# Run the real Hanzo Stack with all services
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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Paths to Hanzo services
HANZO_BASE="/Users/z/work/hanzo"
LLM_PATH="$HANZO_BASE/llm"
API_PATH="$HANZO_BASE/api"
CHAT_PATH="$HANZO_BASE/chat"
SEARCH_PATH="$HANZO_BASE/search"
CLOUD_PATH="$HANZO_BASE/cloud"
IAM_PATH="$HANZO_BASE/iam"
MCP_PATH="$HANZO_BASE/mcp"
SERVICES_PATH="$HANZO_BASE/services"

# PIDs for cleanup
declare -a SERVICE_PIDS

# Cleanup function
cleanup() {
    log "Stopping all services..."
    
    # Kill all service processes
    for pid in "${SERVICE_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    
    # Stop Docker containers
    docker stop hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch hanzo-clickhouse 2>/dev/null || true
    docker rm hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch hanzo-clickhouse 2>/dev/null || true
    
    log "Cleanup complete"
}

trap cleanup EXIT

log "Starting Real Hanzo Stack"
log "========================="

# Step 1: Start infrastructure services
log "Starting infrastructure services..."

# PostgreSQL
docker run -d --name hanzo-postgres \
    -e POSTGRES_USER=hanzo \
    -e POSTGRES_PASSWORD=hanzo123 \
    -e POSTGRES_DB=hanzo \
    -p 5432:5432 \
    postgres:16-alpine

# Redis
docker run -d --name hanzo-redis \
    -p 6379:6379 \
    redis:7-alpine redis-server --requirepass hanzo123

# MongoDB
docker run -d --name hanzo-mongodb \
    -e MONGO_INITDB_ROOT_USERNAME=hanzo \
    -e MONGO_INITDB_ROOT_PASSWORD=hanzo123 \
    -e MONGO_INITDB_DATABASE=hanzo \
    -p 27017:27017 \
    mongo:7

# MinIO
docker run -d --name hanzo-minio \
    -p 9000:9000 -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    minio/minio server /data --console-address ":9001"

# Meilisearch
docker run -d --name hanzo-meilisearch \
    -p 7700:7700 \
    -e MEILI_MASTER_KEY=hanzo123 \
    -e MEILI_ENV=development \
    getmeili/meilisearch:latest

# ClickHouse
docker run -d --name hanzo-clickhouse \
    -p 8123:8123 -p 9000:9000 \
    -e CLICKHOUSE_USER=hanzo \
    -e CLICKHOUSE_PASSWORD=hanzo123 \
    -e CLICKHOUSE_DB=hanzo \
    clickhouse/clickhouse-server:latest

# Wait for infrastructure
log "Waiting for infrastructure to be ready..."
sleep 15

# Check infrastructure health
info "Checking infrastructure health..."
docker exec hanzo-postgres pg_isready -U hanzo && log "✓ PostgreSQL ready" || error "✗ PostgreSQL not ready"
docker exec hanzo-redis redis-cli -a hanzo123 ping | grep -q PONG && log "✓ Redis ready" || error "✗ Redis not ready"
docker exec hanzo-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null && log "✓ MongoDB ready" || error "✗ MongoDB not ready"
curl -sf http://localhost:9000/minio/health/live && log "✓ MinIO ready" || error "✗ MinIO not ready"
curl -sf http://localhost:7700/health && log "✓ Meilisearch ready" || error "✗ Meilisearch not ready"

# Step 2: Start Hanzo LLM Router
if [ -d "$LLM_PATH" ]; then
    log "Starting Hanzo LLM Router..."
    cd "$LLM_PATH"
    
    # Check if it's a Python project
    if [ -f "requirements.txt" ]; then
        info "Setting up Python environment for LLM..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        
        # Set environment variables
        export DATABASE_URL="postgresql://hanzo:hanzo123@localhost:5432/hanzo"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export MASTER_KEY="sk-hanzo-master"
        export PORT=4000
        export MOCK_MODE=true
        
        # Run the service
        if [ -f "main.py" ]; then
            python main.py &
            SERVICE_PIDS+=($!)
            sleep 10
            
            if curl -sf http://localhost:4000/health; then
                log "✓ LLM Router started successfully"
            else
                error "✗ LLM Router failed to start"
            fi
        fi
        
        deactivate
    elif [ -f "docker-compose.yml" ]; then
        info "Starting LLM via Docker Compose..."
        docker compose up -d
        sleep 10
    fi
fi

# Step 3: Start Hanzo API
if [ -d "$API_PATH" ] || [ -d "$HANZO_BASE/api-old" ]; then
    API_DIR="${API_PATH}"
    [ ! -d "$API_DIR" ] && API_DIR="$HANZO_BASE/api-old"
    
    log "Starting Hanzo API from $API_DIR..."
    cd "$API_DIR"
    
    if [ -f "requirements.txt" ]; then
        info "Setting up Python environment for API..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        
        export DATABASE_URL="postgresql://hanzo:hanzo123@localhost:5432/hanzo"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export MINIO_ENDPOINT="localhost:9000"
        export MINIO_ACCESS_KEY="minioadmin"
        export MINIO_SECRET_KEY="minioadmin"
        export PORT=8000
        
        if [ -f "main.py" ]; then
            python main.py &
            SERVICE_PIDS+=($!)
        elif [ -f "app.py" ]; then
            python app.py &
            SERVICE_PIDS+=($!)
        fi
        
        sleep 10
        deactivate
    fi
fi

# Step 4: Start Chat service
if [ -d "$CHAT_PATH" ]; then
    log "Starting Hanzo Chat..."
    cd "$CHAT_PATH"
    
    if [ -f "package.json" ]; then
        info "Installing Node.js dependencies..."
        npm install || pnpm install || bun install
        
        export DATABASE_URL="mongodb://hanzo:hanzo123@localhost:27017/chat?authSource=admin"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export LLM_GATEWAY_URL="http://localhost:4000"
        export NEXTAUTH_URL="http://localhost:3081"
        export NEXTAUTH_SECRET="test-secret"
        export PORT=3081
        
        npm run dev &
        SERVICE_PIDS+=($!)
        sleep 15
    fi
fi

# Step 5: Start Cloud (Langfuse)
if [ -d "$CLOUD_PATH" ]; then
    log "Starting Hanzo Cloud..."
    cd "$CLOUD_PATH"
    
    if [ -f "package.json" ]; then
        info "Installing dependencies..."
        pnpm install --no-frozen-lockfile || npm install
        
        export DATABASE_URL="postgresql://hanzo:hanzo123@localhost:5432/hanzo"
        export CLICKHOUSE_HOST="localhost"
        export CLICKHOUSE_PORT="8123"
        export CLICKHOUSE_USER="hanzo"
        export CLICKHOUSE_PASSWORD="hanzo123"
        export CLICKHOUSE_DATABASE="hanzo"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export NEXTAUTH_URL="http://localhost:3000"
        export NEXTAUTH_SECRET="test-secret"
        export ENCRYPTION_KEY="0000000000000000000000000000000000000000000000000000000000000000"
        export PORT=3000
        
        # Run migrations
        pnpm --filter=web db:migrate || true
        
        pnpm run dev &
        SERVICE_PIDS+=($!)
        sleep 15
    fi
fi

# Step 6: Check all services
log "Checking service health..."
echo ""

# LLM Router
if curl -sf http://localhost:4000/health; then
    log "✓ LLM Router: http://localhost:4000"
else
    error "✗ LLM Router not accessible"
fi

# API
if curl -sf http://localhost:8000/health; then
    log "✓ API: http://localhost:8000"
else
    error "✗ API not accessible"
fi

# Chat
if curl -sf http://localhost:3081; then
    log "✓ Chat: http://localhost:3081"
else
    error "✗ Chat not accessible"
fi

# Cloud
if curl -sf http://localhost:3000; then
    log "✓ Cloud: http://localhost:3000"
else
    error "✗ Cloud not accessible"
fi

# Step 7: Run integration tests
log "Running integration tests..."

# Test 1: LLM Router
info "Testing LLM Router..."
response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer sk-hanzo-master" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Hello Hanzo"}]
    }' || echo "{}")

if echo "$response" | grep -q "choices"; then
    log "✓ LLM Router chat completion works"
else
    error "✗ LLM Router test failed"
    echo "$response"
fi

# Test 2: API Project Creation
info "Testing API..."
project_response=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d '{
        "name": "Integration Test",
        "description": "Real Hanzo Stack Test"
    }' || echo "{}")

if echo "$project_response" | grep -q "id"; then
    log "✓ API project creation works"
    PROJECT_ID=$(echo "$project_response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
else
    error "✗ API test failed"
fi

# Summary
echo ""
echo "========================================="
log "Hanzo Stack is running!"
echo "========================================="
echo ""
echo "Service URLs:"
echo "  LLM Router:  http://localhost:4000"
echo "  API:         http://localhost:8000"
echo "  Chat:        http://localhost:3081"
echo "  Cloud:       http://localhost:3000"
echo "  MinIO:       http://localhost:9001 (minioadmin/minioadmin)"
echo "  Meilisearch: http://localhost:7700"
echo ""
echo "Infrastructure:"
echo "  PostgreSQL:  localhost:5432 (hanzo/hanzo123)"
echo "  Redis:       localhost:6379 (password: hanzo123)"
echo "  MongoDB:     localhost:27017 (hanzo/hanzo123)"
echo "  ClickHouse:  localhost:8123 (hanzo/hanzo123)"
echo ""
log "Press Enter to stop all services..."
read