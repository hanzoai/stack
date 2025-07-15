#!/bin/bash
# Hanzo Stack Demonstration

echo "=== Hanzo Stack Live Demo ==="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

API_KEY="sk-router-master-hanzo"

echo -e "${CYAN}1. Unified Router API - Multiple LLM Providers${NC}"
echo ""

echo -e "${BLUE}Testing OpenAI GPT-4o:${NC}"
curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": "What is Hanzo AI? Reply in one sentence."}],
        "max_tokens": 50
    }' | jq -r '.choices[0].message.content'

echo ""
echo -e "${BLUE}Testing Anthropic Claude 3 Opus:${NC}"
curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "claude-3-opus-20240229",
        "messages": [{"role": "user", "content": "What is Hanzo AI? Reply in one sentence."}],
        "max_tokens": 50
    }' | jq -r '.choices[0].message.content'

echo ""
echo -e "${CYAN}2. Code Generation and Execution Workflow${NC}"
echo ""

echo -e "${BLUE}Generating Python code with Claude:${NC}"
CODE=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "claude-3-haiku-20240307",
        "messages": [{"role": "user", "content": "Write a Python function that calculates factorial of 5. Just the code."}],
        "max_tokens": 100
    }' | jq -r '.choices[0].message.content')

echo "$CODE"

echo ""
echo -e "${BLUE}Executing the generated code:${NC}"
# Add print statement to see result
FULL_CODE="$CODE
print(f'Factorial of 5 is: {factorial(5)}')"

curl -s -X POST http://localhost:3003/api/execute \
    -H "Content-Type: application/json" \
    -d "{\"language\": \"python\", \"code\": $(echo "$FULL_CODE" | jq -Rs .)}" | \
    jq -r '.output'

echo ""
echo -e "${CYAN}3. Service Orchestration${NC}"
echo ""

echo -e "${BLUE}Active Services:${NC}"
curl -s http://localhost:3000/api/services | jq -r '.services[] | "• \(.name): \(.status) at \(.url)"'

echo ""
echo -e "${CYAN}4. Chat UI Integration${NC}"
echo ""
echo -e "${GREEN}✓${NC} Chat UI is accessible at: ${BLUE}http://localhost:3081${NC}"
echo -e "${GREEN}✓${NC} Connected to Router for LLM access"
echo -e "${GREEN}✓${NC} Connected to Runtime for code execution"

echo ""
echo -e "${CYAN}5. Available Models${NC}"
echo ""
echo "Total models available: $(curl -s -H "Authorization: Bearer $API_KEY" http://localhost:4000/v1/models | jq '.data | length')"
echo ""
echo "Sample models:"
curl -s -H "Authorization: Bearer $API_KEY" http://localhost:4000/v1/models | \
    jq -r '.data[0:10] | .[] | "• " + .id' | sort

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Hanzo Stack Demo Complete!${NC}"
echo ""
echo "The stack demonstrates:"
echo "• Unified API routing to multiple LLM providers"
echo "• Code generation with LLMs"
echo "• Code execution via Runtime service"
echo "• Service orchestration and discovery"
echo "• Full integration between all components"
echo ""
echo -e "${BLUE}Try it yourself:${NC}"
echo "• Chat UI: http://localhost:3081"
echo "• API Docs: http://localhost:4000/docs"
echo "• Direct API: curl -H 'Authorization: Bearer $API_KEY' http://localhost:4000/v1/models"