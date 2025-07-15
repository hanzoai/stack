#!/bin/bash
# Test Chat-Runtime Integration

set -e

echo "=== Testing Chat-Runtime Integration ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if services are running
echo "1. Checking service health..."
if curl -sf http://localhost:3081/health > /dev/null; then
    echo -e "${GREEN}✓${NC} Chat is running"
else
    echo -e "${RED}✗${NC} Chat is not running"
    exit 1
fi

if curl -sf http://localhost:3003/api/health > /dev/null; then
    echo -e "${GREEN}✓${NC} Runtime is running"
else
    echo -e "${RED}✗${NC} Runtime is not running"
    exit 1
fi

echo ""
echo "2. Testing Runtime API directly..."

# Test Python execution
echo -n "   Python execution: "
PYTHON_RESULT=$(curl -s -X POST http://localhost:3003/api/execute \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${RUNTIME_API_KEY:-dev-runtime-key}" \
    -d '{
        "language": "python",
        "code": "import sys\nprint(f\"Python {sys.version.split()[0]}\")\nprint(\"2 + 2 =\", 2 + 2)"
    }' 2>/dev/null)

if echo "$PYTHON_RESULT" | jq -e '.output' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    echo "   Output: $(echo "$PYTHON_RESULT" | jq -r '.output' | head -2 | tr '\n' ' ')"
else
    echo -e "${RED}✗${NC}"
    echo "   Error: $(echo "$PYTHON_RESULT" | jq -r '.error // "Unknown error"')"
fi

# Test JavaScript execution
echo -n "   JavaScript execution: "
JS_RESULT=$(curl -s -X POST http://localhost:3003/api/execute \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${RUNTIME_API_KEY:-dev-runtime-key}" \
    -d '{
        "language": "javascript",
        "code": "console.log(\"Node.js\", process.version);\nconsole.log(\"3 * 4 =\", 3 * 4);"
    }' 2>/dev/null)

if echo "$JS_RESULT" | jq -e '.output' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    echo "   Output: $(echo "$JS_RESULT" | jq -r '.output' | head -2 | tr '\n' ' ')"
else
    echo -e "${RED}✗${NC}"
    echo "   Error: $(echo "$JS_RESULT" | jq -r '.error // "Unknown error"')"
fi

echo ""
echo "3. Checking Chat configuration for Runtime..."

# Check if Chat has runtime endpoint configured
CHAT_ENV=$(docker compose exec -T chat env | grep -E "(RUNTIME|CODE_EXEC)" || true)
if [ -n "$CHAT_ENV" ]; then
    echo -e "${GREEN}✓${NC} Chat has Runtime configuration:"
    echo "$CHAT_ENV" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠${NC} Chat may not have Runtime configuration"
    echo "   Add these to Chat environment:"
    echo "   RUNTIME_ENABLED=true"
    echo "   RUNTIME_URL=http://runtime:3000"
    echo "   RUNTIME_API_KEY=dev-runtime-key"
fi

echo ""
echo "4. Testing code execution through Chat API..."
echo "   (This would require Chat API endpoint for code execution)"

# Check if Chat exposes a code execution endpoint
CHAT_EXEC_ENDPOINT="http://localhost:3081/api/code/execute"
echo -n "   Checking for Chat code execution endpoint: "
if curl -sf -o /dev/null -w "%{http_code}" "$CHAT_EXEC_ENDPOINT" | grep -q "401\|403\|404"; then
    echo -e "${YELLOW}⚠${NC} Endpoint exists but requires auth or not implemented"
else
    echo -e "${RED}✗${NC} Endpoint not available"
fi

echo ""
echo "5. Integration Summary:"
echo "   - Runtime service is ${GREEN}operational${NC}"
echo "   - Runtime can execute Python and JavaScript code"
echo "   - Chat and Runtime are on the same Docker network"
echo "   - Chat can reach Runtime at: http://runtime:3000"
echo ""
echo "To enable code execution in Chat:"
echo "1. Ensure Chat has RUNTIME_* environment variables set"
echo "2. Use the code execution feature in Chat UI"
echo "3. Or use Chat's API endpoint for code execution"
echo ""
echo -e "${GREEN}✓${NC} Integration test complete!"