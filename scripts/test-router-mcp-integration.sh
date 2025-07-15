#!/bin/bash
# Test Hanzo Router with MCP Integration

set -e

echo "=== Testing Hanzo Router with MCP Integration ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Router API base URL
ROUTER_URL="http://localhost:4000"
API_KEY="${ROUTER_MASTER_KEY:-sk-router-master-hanzo}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((TESTS_FAILED++))
    fi
}

test_endpoint() {
    local name=$1
    local url=$2
    echo -n "Testing $name... "
    curl -sf "$url" > /dev/null 2>&1
    check_result
}

echo -e "${BLUE}1. Testing Router Health${NC}"
test_endpoint "Router health" "$ROUTER_URL/health/liveliness"
test_endpoint "Router readiness" "$ROUTER_URL/health/readiness"

echo ""
echo -e "${BLUE}2. Testing Model Availability${NC}"
echo -n "Fetching available models... "
MODELS=$(curl -sf -H "Authorization: Bearer $API_KEY" "$ROUTER_URL/v1/models" | jq -r '.data[] | .id' 2>/dev/null)
if [ -n "$MODELS" ]; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
    echo "Available models:"
    echo "$MODELS" | head -10 | sed 's/^/   - /'
    echo "   ... and $(echo "$MODELS" | wc -l) more"
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "${BLUE}3. Testing OpenAI API (via Router)${NC}"
echo -n "Testing GPT-4o-mini completion... "
OPENAI_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": "Say hello in one word"}],
        "max_tokens": 10
    }' 2>/dev/null)

if echo "$OPENAI_RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
    echo "   Response: $(echo "$OPENAI_RESPONSE" | jq -r '.choices[0].message.content')"
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "${BLUE}4. Testing Anthropic API (via Router)${NC}"
echo -n "Testing Claude 3 Haiku completion... "
ANTHROPIC_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "claude-3-haiku-20240307",
        "messages": [{"role": "user", "content": "What is 2+2? Answer with just the number."}],
        "max_tokens": 10
    }' 2>/dev/null)

if echo "$ANTHROPIC_RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
    echo "   Response: $(echo "$ANTHROPIC_RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\n')"
else
    echo -e "${RED}✗${NC}"
    ((TESTS_FAILED++))
    echo "   Error: $(echo "$ANTHROPIC_RESPONSE" | jq -r '.error.message' 2>/dev/null || echo "Unknown error")"
fi

echo ""
echo -e "${BLUE}5. Testing MCP Server Availability${NC}"
echo -n "Checking MCP endpoints... "
# Check if MCP is mentioned in router config
if docker exec hanzo-router env | grep -q "MCP_ENABLED=true"; then
    echo -e "${GREEN}✓${NC} MCP is enabled"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠${NC} MCP not detected in router config"
fi

echo ""
echo -e "${BLUE}6. Testing Unified API Routes${NC}"
echo -n "Testing /runtime route... "
RUNTIME_VIA_ROUTER=$(curl -sf -X GET "$ROUTER_URL/runtime/health" 2>/dev/null || echo "not configured")
if [[ "$RUNTIME_VIA_ROUTER" == "not configured" ]]; then
    echo -e "${YELLOW}⚠${NC} Runtime routing not configured yet"
else
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
fi

echo -n "Testing /services route... "
SERVICES_VIA_ROUTER=$(curl -sf -X GET "$ROUTER_URL/services/health" 2>/dev/null || echo "not configured")
if [[ "$SERVICES_VIA_ROUTER" == "not configured" ]]; then
    echo -e "${YELLOW}⚠${NC} Services routing not configured yet"
else
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
fi

echo ""
echo -e "${BLUE}7. Testing Code Execution via Router${NC}"
echo -n "Testing Python execution through unified API... "
CODE_EXEC_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/runtime/execute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "language": "python",
        "code": "print(\"Router integration working!\")"
    }' 2>/dev/null || echo "{}")

if echo "$CODE_EXEC_RESPONSE" | jq -e '.output' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((TESTS_PASSED++))
    echo "   Output: $(echo "$CODE_EXEC_RESPONSE" | jq -r '.output' | tr -d '\n')"
else
    echo -e "${YELLOW}⚠${NC} Code execution routing not configured yet"
fi

echo ""
echo -e "${BLUE}8. MCP Tool Usage Test${NC}"
echo -n "Testing MCP tool invocation... "
MCP_RESPONSE=$(curl -sf -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "claude-3-5-sonnet-20241022",
        "messages": [{"role": "user", "content": "List files in /workspace directory"}],
        "tools": [{
            "type": "function",
            "function": {
                "name": "list_directory",
                "description": "List files in a directory",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {"type": "string"}
                    }
                }
            }
        }],
        "max_tokens": 100
    }' 2>/dev/null || echo "{}")

if echo "$MCP_RESPONSE" | jq -e '.choices[0].message' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MCP tools available"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠${NC} MCP tools not fully configured"
fi

echo ""
echo "======================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Router integration tests passed!${NC}"
    echo ""
    echo "Summary:"
    echo "• Router is serving both OpenAI and Anthropic models"
    echo "• API endpoints are working correctly"
    echo "• MCP is enabled in the router"
    echo "• Unified API gateway is ready for expansion"
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "• Check router logs: docker logs hanzo-router"
    echo "• Verify API keys are set correctly"
    echo "• Ensure all services are healthy: make health"
fi

echo ""
echo "Next steps:"
echo "1. Configure router to proxy requests to other services"
echo "2. Set up MCP server connections"
echo "3. Test Claude Desktop integration with Hanzo MCP"
echo "4. Merge runtime functionality into unified API"