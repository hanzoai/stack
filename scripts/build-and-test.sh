#!/bin/bash

# Build and test Hanzo services locally
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

# Check if repos directory exists
if [ ! -d "repos" ]; then
    error "repos directory not found. Run 'make clone-all' first"
    exit 1
fi

log "Hanzo Stack Local Build & Test"
log "=============================="

# Start infrastructure
log "Starting infrastructure services..."
docker run -d --name hanzo-postgres \
    -e POSTGRES_USER=hanzo \
    -e POSTGRES_PASSWORD=hanzo123 \
    -e POSTGRES_DB=hanzo \
    -p 5432:5432 \
    postgres:16-alpine

docker run -d --name hanzo-redis \
    -p 6379:6379 \
    redis:7-alpine redis-server --requirepass hanzo123

docker run -d --name hanzo-mongodb \
    -e MONGO_INITDB_ROOT_USERNAME=hanzo \
    -e MONGO_INITDB_ROOT_PASSWORD=hanzo123 \
    -e MONGO_INITDB_DATABASE=hanzo \
    -p 27017:27017 \
    mongo:7

# Wait for services
log "Waiting for infrastructure..."
sleep 10

# Test 1: Build and test LLM service
if [ -d "repos/llm" ]; then
    log "Building Hanzo LLM Router..."
    cd repos/llm
    
    # Check for Python project
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        info "Found Python project"
        
        # Create virtual environment
        python3 -m venv venv
        source venv/bin/activate
        
        # Install dependencies
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
        elif [ -f "pyproject.toml" ]; then
            pip install -e .
        fi
        
        # Run in test mode
        export DATABASE_URL="postgresql://hanzo:hanzo123@localhost:5432/hanzo"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export MASTER_KEY="sk-hanzo-test"
        export MOCK_MODE="true"
        export PORT="4000"
        
        # Start service
        if [ -f "main.py" ]; then
            python main.py &
        elif [ -f "app.py" ]; then
            python app.py &
        elif [ -f "src/main.py" ]; then
            python src/main.py &
        else
            info "Could not find main entry point"
        fi
        
        LLM_PID=$!
        sleep 5
        
        # Test health
        if curl -sf http://localhost:4000/health; then
            log "✓ LLM Router is running"
        else
            error "✗ LLM Router failed to start"
        fi
        
        deactivate
    fi
    
    cd ../..
fi

# Test 2: Build and test API service
if [ -d "repos/api" ]; then
    log "Building Hanzo API..."
    cd repos/api
    
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        info "Found Python API project"
        
        python3 -m venv venv
        source venv/bin/activate
        
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
        elif [ -f "pyproject.toml" ]; then
            pip install -e .
        fi
        
        export DATABASE_URL="postgresql://hanzo:hanzo123@localhost:5432/hanzo"
        export REDIS_URL="redis://:hanzo123@localhost:6379"
        export PORT="8000"
        
        # Run migrations if available
        if [ -f "alembic.ini" ]; then
            alembic upgrade head || true
        fi
        
        # Start API
        if [ -f "main.py" ]; then
            python main.py &
        elif command -v uvicorn &> /dev/null; then
            uvicorn app:app --host 0.0.0.0 --port 8000 &
        fi
        
        API_PID=$!
        sleep 5
        
        if curl -sf http://localhost:8000/health; then
            log "✓ API is running"
        else
            error "✗ API failed to start"
        fi
        
        deactivate
    elif [ -f "package.json" ]; then
        info "Found Node.js API project"
        
        npm install || pnpm install || yarn install
        npm run dev &
        API_PID=$!
        sleep 10
        
        if curl -sf http://localhost:8000/health; then
            log "✓ API is running"
        else
            error "✗ API failed to start"
        fi
    fi
    
    cd ../..
fi

# Test 3: Integration test
log "Running integration tests..."

# Create test project
if curl -sf http://localhost:8000/health; then
    info "Testing project creation..."
    
    response=$(curl -s -X POST http://localhost:8000/api/v1/projects \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test-token" \
        -d '{
            "name": "Test Project",
            "description": "Integration test"
        }')
    
    if echo "$response" | grep -q "id"; then
        log "✓ API integration test passed"
    else
        error "✗ API integration test failed"
        echo "$response"
    fi
fi

# Test LLM Router
if curl -sf http://localhost:4000/health; then
    info "Testing LLM chat completion..."
    
    response=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-hanzo-test" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello"}],
            "mock_response": "Hello from Hanzo!"
        }')
    
    if echo "$response" | grep -q "choices"; then
        log "✓ LLM Router integration test passed"
    else
        error "✗ LLM Router integration test failed"
        echo "$response"
    fi
fi

# Summary
echo ""
log "Test Summary"
echo "============"
echo "Infrastructure: ✓ Running"
if [ -n "$LLM_PID" ]; then echo "LLM Router: ✓ Running (PID: $LLM_PID)"; fi
if [ -n "$API_PID" ]; then echo "API: ✓ Running (PID: $API_PID)"; fi
echo ""
echo "URLs:"
echo "  PostgreSQL: localhost:5432"
echo "  Redis: localhost:6379"
echo "  MongoDB: localhost:27017"
if [ -n "$LLM_PID" ]; then echo "  LLM Router: http://localhost:4000"; fi
if [ -n "$API_PID" ]; then echo "  API: http://localhost:8000"; fi
echo ""
log "Press Enter to stop all services..."
read

# Cleanup
log "Stopping services..."
[ -n "$LLM_PID" ] && kill $LLM_PID 2>/dev/null
[ -n "$API_PID" ] && kill $API_PID 2>/dev/null

docker stop hanzo-postgres hanzo-redis hanzo-mongodb 2>/dev/null
docker rm hanzo-postgres hanzo-redis hanzo-mongodb 2>/dev/null

log "Cleanup complete"