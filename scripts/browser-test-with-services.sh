#!/bin/bash

# Start services and run browser tests
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

# Cleanup function
cleanup() {
    log "Stopping test services..."
    pkill -f "mock-llm-router.py" 2>/dev/null || true
    pkill -f "mock-api.py" 2>/dev/null || true
}

trap cleanup EXIT

log "Starting services for browser testing..."

# Start mock services in background
python /tmp/mock-llm-router.py > /tmp/llm-router.log 2>&1 &
LLM_PID=$!

python /tmp/mock-api.py > /tmp/api.log 2>&1 &
API_PID=$!

# Wait for services to start
log "Waiting for services to be ready..."
sleep 5

# Check if services are running
if curl -sf http://localhost:4000/health >/dev/null && curl -sf http://localhost:8000/health >/dev/null; then
    log "✅ Services are running"
    
    # Show service info
    echo ""
    info "Service Status:"
    curl -s http://localhost:4000/health | jq . || echo "LLM Router: http://localhost:4000"
    curl -s http://localhost:8000/health | jq . || echo "API: http://localhost:8000"
    echo ""
    
    log "Services are ready for browser testing!"
    log "You can now:"
    echo "  - Navigate to http://localhost:4000/health"
    echo "  - Navigate to http://localhost:8000/health"
    echo "  - Navigate to http://localhost:8000/docs"
    echo "  - Navigate to http://localhost:9001 (MinIO Console)"
    echo ""
    log "Press Enter to stop services..."
    read
else
    error "Services failed to start"
    cat /tmp/llm-router.log
    cat /tmp/api.log
fi