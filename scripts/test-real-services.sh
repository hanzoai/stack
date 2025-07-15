#!/bin/bash

# Test real Hanzo services
set -e

# Colors
GREEN='\033[0;32m'
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

log "Testing Real Hanzo Services"
log "==========================="

# Test infrastructure
log "Testing infrastructure services..."

# PostgreSQL
if docker exec hanzo-postgres pg_isready -U hanzo &>/dev/null; then
    log "✓ PostgreSQL is ready"
else
    error "✗ PostgreSQL not ready"
fi

# Redis
if docker exec hanzo-redis redis-cli -a hanzo123 ping | grep -q PONG; then
    log "✓ Redis is ready"
else
    error "✗ Redis not ready"
fi

# MongoDB
if docker exec hanzo-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
    log "✓ MongoDB is ready"
else
    error "✗ MongoDB not ready"
fi

# MinIO
if curl -sf http://localhost:9000/minio/health/live; then
    log "✓ MinIO is ready"
else
    error "✗ MinIO not ready"
fi

# Meilisearch
if curl -sf http://localhost:7700/health; then
    log "✓ Meilisearch is ready"
else
    error "✗ Meilisearch not ready"
fi

# Try to run a simple Python service
log "Starting test API service..."

# Create a simple test API
cat > /tmp/test-api.py << 'EOF'
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "healthy", "service": "test-api"}

@app.get("/")
def root():
    return {"message": "Hanzo Test API"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Install dependencies if needed
pip install fastapi uvicorn 2>/dev/null || true

# Run the test API
python /tmp/test-api.py &
API_PID=$!

sleep 5

# Test the API
if curl -sf http://localhost:8000/health; then
    log "✓ Test API is running"
else
    error "✗ Test API failed to start"
fi

# Clean up
kill $API_PID 2>/dev/null || true

log "Test complete!"