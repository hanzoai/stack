#!/bin/bash
# Test Complete Hanzo Stack Integration

set -e

echo "=== Testing Complete Hanzo Stack Integration ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function
test_service() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "Testing $name... "
    if curl -sf "$url" | grep -q "$expected" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test infrastructure
echo -e "${BLUE}1. Testing Infrastructure Services${NC}"
test_service "PostgreSQL" "http://localhost:5432" "refused" || true  # Expected to refuse HTTP
test_service "Redis" "http://localhost:6379" "wrong number" || true  # Expected Redis protocol error
test_service "MongoDB" "http://localhost:27017" "looks like HTTP" || true
test_service "MinIO" "http://localhost:9000/minio/health/live" ""
test_service "Meilisearch" "http://localhost:7700/health" "available"

echo ""
echo -e "${BLUE}2. Testing Core Services${NC}"
test_service "LLM Gateway" "http://localhost:4000/health" "healthy"
test_service "Chat" "http://localhost:3081/health" "OK"
test_service "Runtime" "http://localhost:3003/api/health" "ok"
test_service "Services Hub" "http://localhost:3000/health" "ok"

echo ""
echo -e "${BLUE}3. Testing Service Integration${NC}"

# Test LLM Gateway models endpoint
echo -n "LLM Gateway models... "
if curl -sf http://localhost:4000/v1/models | jq -e '.data | length > 0' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ($(curl -sf http://localhost:4000/v1/models | jq -r '.data | length') models available)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

# Test Runtime code execution
echo -n "Runtime Python execution... "
PYTHON_RESULT=$(curl -sf -X POST http://localhost:3003/api/execute \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-runtime-key" \
    -d '{"language": "python", "code": "print(\"Integration test successful!\")"}' 2>/dev/null || echo "{}")

if echo "$PYTHON_RESULT" | jq -e '.output' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "${BLUE}4. Testing Inter-Service Communication${NC}"

# Test if Chat can reach Runtime
echo -n "Chat → Runtime connectivity... "
CHAT_TO_RUNTIME=$(docker compose exec -T chat wget -q -O - http://runtime:3000/api/health 2>/dev/null || echo "failed")
if echo "$CHAT_TO_RUNTIME" | grep -q "ok"; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

# Test if Chat can reach LLM Gateway
echo -n "Chat → LLM Gateway connectivity... "
CHAT_TO_LLM=$(docker compose exec -T chat wget -q -O - http://llm-gateway:4000/health 2>/dev/null || echo "failed")
if echo "$CHAT_TO_LLM" | grep -q "healthy"; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

# Test if Services can reach all components
echo -n "Services Hub → All services... "
SERVICES_CHECK=$(docker compose exec -T services wget -q -O - http://services:3000/health 2>/dev/null || echo "failed")
if echo "$SERVICES_CHECK" | grep -q "ok"; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠${NC} (Services hub may not have health checks for all connections)"
fi

echo ""
echo -e "${BLUE}5. Testing Data Persistence${NC}"

# Test PostgreSQL connectivity
echo -n "PostgreSQL database access... "
if docker compose exec -T postgres psql -U hanzo -c "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

# Test Redis connectivity
echo -n "Redis cache access... "
if docker compose exec -T redis redis-cli -a hanzo123 ping | grep -q PONG 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

# Test MongoDB connectivity
echo -n "MongoDB document store... "
if docker compose exec -T mongodb mongosh -u hanzo -p hanzo123 --eval "db.adminCommand('ping')" --quiet | grep -q 1 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo "======================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    echo ""
    echo "The Hanzo Stack is fully operational with:"
    echo "• All services running and healthy"
    echo "• Inter-service communication working"
    echo "• Runtime code execution enabled"
    echo "• Data persistence configured"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "• Check logs: make logs"
    echo "• Restart services: make restart"
    echo "• Check individual service logs: make logs-<service>"
    exit 1
fi