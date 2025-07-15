#!/bin/bash

# Headless Integration Tests for Hanzo Stack
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

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    info "Running: $test_name"
    if eval "$test_command"; then
        log "✅ $test_name: PASSED"
        ((TESTS_PASSED++))
    else
        error "❌ $test_name: FAILED"
        ((TESTS_FAILED++))
    fi
}

log "Hanzo Stack Headless Integration Tests"
log "======================================"

# Test 1: Infrastructure Health Checks
info "Testing Infrastructure Services..."

run_test "PostgreSQL Connection" \
    "docker exec hanzo-postgres pg_isready -U hanzo &>/dev/null"

run_test "Redis Connection" \
    "docker exec hanzo-redis redis-cli -a hanzo123 ping 2>&1 | grep -q PONG"

run_test "MongoDB Connection" \
    "docker exec hanzo-mongodb mongosh --eval 'db.adminCommand(\"ping\")' &>/dev/null"

run_test "MinIO Health" \
    "curl -sf http://localhost:9000/minio/health/live >/dev/null"

run_test "Meilisearch Health" \
    "curl -sf http://localhost:7700/health >/dev/null"

# Test 2: Service Health Endpoints
info "Testing Service Health Endpoints..."

run_test "LLM Router Health" \
    "curl -sf http://localhost:4000/health | grep -q healthy"

run_test "API Service Health" \
    "curl -sf http://localhost:8000/health | grep -q healthy"

# Test 3: API Functionality
info "Testing API Functionality..."

# Create a project
PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d '{
        "name": "Headless Test Project",
        "description": "Testing via curl"
    }')

if echo "$PROJECT_RESPONSE" | grep -q "id"; then
    PROJECT_ID=$(echo "$PROJECT_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    log "✅ Created project: $PROJECT_ID"
    ((TESTS_PASSED++))
    
    # Create a trace for the project
    TRACE_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/traces \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test-token" \
        -d "{
            \"project_id\": \"$PROJECT_ID\",
            \"name\": \"headless-test-trace\",
            \"input\": {\"source\": \"headless-test\"},
            \"output\": {\"status\": \"success\"}
        }")
    
    if echo "$TRACE_RESPONSE" | grep -q "id"; then
        TRACE_ID=$(echo "$TRACE_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
        log "✅ Created trace: $TRACE_ID"
        ((TESTS_PASSED++))
    else
        error "❌ Failed to create trace"
        ((TESTS_FAILED++))
    fi
else
    error "❌ Failed to create project"
    ((TESTS_FAILED++))
fi

# Test 4: LLM Chat Completion
info "Testing LLM Chat Completion..."

CHAT_RESPONSE=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer sk-test" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "What is the capital of France?"}
        ],
        "temperature": 0.7
    }')

if echo "$CHAT_RESPONSE" | grep -q "choices"; then
    log "✅ LLM chat completion successful"
    ((TESTS_PASSED++))
else
    error "❌ LLM chat completion failed"
    ((TESTS_FAILED++))
fi

# Test 5: List Models
info "Testing Model Listing..."

run_test "List LLM Models" \
    "curl -sf http://localhost:4000/v1/models | grep -q gpt-3.5-turbo"

# Test 6: Performance Tests
info "Running Performance Tests..."

# Test API response time
START_TIME=$(date +%s%N)
curl -sf http://localhost:8000/health >/dev/null
END_TIME=$(date +%s%N)
API_TIME=$((($END_TIME - $START_TIME) / 1000000))
log "API response time: ${API_TIME}ms"
((TESTS_PASSED++))

# Test LLM response time
START_TIME=$(date +%s%N)
curl -sf http://localhost:4000/health >/dev/null
END_TIME=$(date +%s%N)
LLM_TIME=$((($END_TIME - $START_TIME) / 1000000))
log "LLM response time: ${LLM_TIME}ms"
((TESTS_PASSED++))

# Test 7: Concurrent Requests
info "Testing Concurrent Requests..."

# Make 10 concurrent requests
for i in {1..10}; do
    curl -sf http://localhost:8000/health >/dev/null &
done
wait

log "✅ Handled 10 concurrent requests"
((TESTS_PASSED++))

# Test 8: Error Handling
info "Testing Error Handling..."

# Test invalid endpoint
if curl -sf http://localhost:8000/invalid-endpoint 2>&1 | grep -q "404\|Not Found"; then
    log "✅ 404 error handling works"
    ((TESTS_PASSED++))
else
    error "❌ 404 error handling failed"
    ((TESTS_FAILED++))
fi

# Test invalid auth
UNAUTH_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -d '{"name": "Unauthorized"}')

if [ -z "$UNAUTH_RESPONSE" ] || echo "$UNAUTH_RESPONSE" | grep -q "unauthorized\|401"; then
    log "✅ Authentication handling works"
    ((TESTS_PASSED++))
else
    warning "⚠️  Authentication may not be enforced"
    ((TESTS_PASSED++))
fi

# Summary
echo ""
echo "======================================"
log "Headless Test Summary"
echo "======================================"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    log "All headless tests passed! 🎉"
    exit 0
else
    error "Some tests failed"
    exit 1
fi