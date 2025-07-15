#!/bin/bash
# Complete End-to-End Hanzo Stack Integration Test

set -e

echo "=== Complete Hanzo Stack Integration Test ==="
echo "Testing all services working together"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ROUTER_URL="http://localhost:4000"
RUNTIME_URL="http://localhost:3003"
SERVICES_URL="http://localhost:3000"
CHAT_URL="http://localhost:3081"
API_KEY="sk-router-master-hanzo"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. Infrastructure Services${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test all infrastructure
SERVICES=(
    "PostgreSQL:5432"
    "Redis:6379"
    "MongoDB:27017"
    "MinIO:9000"
    "Meilisearch:7700"
)

for service in "${SERVICES[@]}"; do
    name="${service%%:*}"
    port="${service##*:}"
    if nc -z localhost $port 2>/dev/null; then
        test_pass "$name (port $port)"
    else
        test_fail "$name (port $port)"
    fi
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Core Services Health${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Router health
if curl -sf "$ROUTER_URL/health/liveliness" | grep -q "alive"; then
    test_pass "Router (Unified API Gateway)"
else
    test_fail "Router (Unified API Gateway)"
fi

# Runtime health
if curl -sf "$RUNTIME_URL/api/health" | jq -r '.status' | grep -q "ok"; then
    test_pass "Runtime (Code Execution)"
else
    test_fail "Runtime (Code Execution)"
fi

# Services health
if curl -sf "$SERVICES_URL/health" | jq -r '.status' | grep -q "ok"; then
    test_pass "Services Hub (Orchestration)"
else
    test_fail "Services Hub (Orchestration)"
fi

# Chat health
if curl -sf "$CHAT_URL/health" | grep -q "OK"; then
    test_pass "Chat UI"
else
    test_fail "Chat UI"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. Router Model Availability${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check models
MODEL_COUNT=$(curl -sf -H "Authorization: Bearer $API_KEY" "$ROUTER_URL/v1/models" | jq '.data | length')
if [ "$MODEL_COUNT" -gt 0 ]; then
    test_pass "Models loaded: $MODEL_COUNT available"
    
    # Show some models
    echo "   Sample models:"
    curl -sf -H "Authorization: Bearer $API_KEY" "$ROUTER_URL/v1/models" | \
        jq -r '.data[0:5] | .[] | "   • " + .id' | head -5
else
    test_fail "No models available"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. LLM API Tests (via Router)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test OpenAI
echo -n "Testing OpenAI (GPT-4o-mini)... "
OPENAI_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": "Reply with: OK"}],
        "max_tokens": 10
    }' 2>/dev/null | jq -r '.choices[0].message.content' | tr -d '\n')

if [[ "$OPENAI_RESPONSE" == *"OK"* ]]; then
    test_pass "Response: $OPENAI_RESPONSE"
else
    test_fail "OpenAI test failed"
fi

# Test Anthropic
echo -n "Testing Anthropic (Claude 3 Haiku)... "
ANTHROPIC_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "claude-3-haiku-20240307",
        "messages": [{"role": "user", "content": "Reply with: OK"}],
        "max_tokens": 10
    }' 2>/dev/null | jq -r '.choices[0].message.content' | tr -d '\n')

if [[ "$ANTHROPIC_RESPONSE" == *"OK"* ]]; then
    test_pass "Response: $ANTHROPIC_RESPONSE"
else
    test_fail "Anthropic test failed"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. Runtime Code Execution${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test Python
echo -n "Python execution... "
PYTHON_RESULT=$(curl -sf -X POST "$RUNTIME_URL/api/execute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-runtime-key" \
    -d '{"language": "python", "code": "print(\"Python: OK\")"}' | jq -r '.output' 2>/dev/null | tr -d '\n')

if [[ "$PYTHON_RESULT" == *"Python: OK"* ]]; then
    test_pass "$PYTHON_RESULT"
else
    test_fail "Python execution failed"
fi

# Test JavaScript
echo -n "JavaScript execution... "
JS_RESULT=$(curl -sf -X POST "$RUNTIME_URL/api/execute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-runtime-key" \
    -d '{"language": "javascript", "code": "console.log(\"JavaScript: OK\")"}' | jq -r '.output' 2>/dev/null | tr -d '\n')

if [[ "$JS_RESULT" == *"JavaScript: OK"* ]]; then
    test_pass "$JS_RESULT"
else
    test_fail "JavaScript execution failed"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. Service Integration Tests${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test Chat -> Router
echo -n "Chat → Router connectivity... "
if docker exec hanzo-chat wget -q -O - http://router:4000/health/liveliness 2>/dev/null | grep -q "alive"; then
    test_pass "Connected"
else
    test_fail "Connection failed"
fi

# Test Chat -> Runtime
echo -n "Chat → Runtime connectivity... "
if docker exec hanzo-chat wget -q -O - http://runtime:3000/api/health 2>/dev/null | grep -q "ok"; then
    test_pass "Connected"
else
    test_fail "Connection failed"
fi

# Test service listing
echo -n "Service registry... "
SERVICE_COUNT=$(curl -sf "$SERVICES_URL/api/services" | jq '.services | length' 2>/dev/null)
if [ "$SERVICE_COUNT" -gt 0 ]; then
    test_pass "$SERVICE_COUNT services registered"
else
    test_fail "No services registered"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. End-to-End Workflow Test${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Complex test: Use LLM to generate code, then execute it
echo "Testing LLM → Code Generation → Execution workflow..."

# Step 1: Generate code with LLM
echo -n "1. Generating Python code with GPT-4o-mini... "
CODE_GENERATION=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": "Write a Python function that returns the string \"Integration test successful!\". Just the function code, no explanation."}],
        "max_tokens": 100
    }' 2>/dev/null | jq -r '.choices[0].message.content')

if [ -n "$CODE_GENERATION" ]; then
    test_pass "Code generated"
    echo "   Generated code preview: $(echo "$CODE_GENERATION" | head -1)..."
else
    test_fail "Code generation failed"
fi

# Step 2: Execute the generated code
echo -n "2. Executing generated code... "
# Add a call to the function
FULL_CODE="${CODE_GENERATION}
print(integration_test())"

EXECUTION_RESULT=$(curl -sf -X POST "$RUNTIME_URL/api/execute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-runtime-key" \
    -d "{\"language\": \"python\", \"code\": $(echo "$FULL_CODE" | jq -Rs .)}" | jq -r '.output' 2>/dev/null)

if [[ "$EXECUTION_RESULT" == *"Integration test successful"* ]]; then
    test_pass "Output: $EXECUTION_RESULT"
else
    test_fail "Execution failed or unexpected output"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. MCP Integration Check${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if MCP is configured
echo -n "MCP configuration... "
if docker exec hanzo-router env | grep -q "MCP_ENABLED=true"; then
    test_pass "MCP is enabled"
else
    test_fail "MCP not enabled"
fi

# Check workspace mount
echo -n "Workspace mount... "
if docker exec hanzo-router ls /workspace >/dev/null 2>&1; then
    test_pass "/workspace is accessible"
else
    test_fail "/workspace not accessible"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo ""
    echo -e "${GREEN}The Hanzo Stack is fully operational with:${NC}"
    echo "• All infrastructure services running"
    echo "• Router serving both OpenAI and Anthropic models"
    echo "• Runtime executing Python and JavaScript code"
    echo "• Services interconnected and communicating"
    echo "• End-to-end LLM → Code execution workflow working"
    echo "• MCP support enabled"
    echo ""
    echo -e "${BLUE}Access Points:${NC}"
    echo "• Chat UI: http://localhost:3081"
    echo "• Router API: http://localhost:4000/v1"
    echo "• Runtime API: http://localhost:3003/api"
    echo "• Services Hub: http://localhost:3000"
    echo "• MinIO Console: http://localhost:9001"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Configure MCP servers for tool usage"
    echo "2. Set up unified API routes in router"
    echo "3. Test with Claude Desktop via MCP"
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please check:"
    echo "• Service logs: docker compose logs [service-name]"
    echo "• Container status: docker compose ps"
    echo "• Network connectivity: docker network ls"
fi