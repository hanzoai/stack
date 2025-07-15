#!/bin/bash
# Test Hanzo Stack Integration

echo "=== Hanzo Stack Integration Test ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Test Router API
echo -e "${BLUE}1. Testing Router API...${NC}"
ROUTER_RESPONSE=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-router-master-hanzo" \
  -d '{"model": "gpt-4o-mini", "messages": [{"role": "user", "content": "Say hello to Hanzo"}], "max_tokens": 20}' \
  | jq -r '.choices[0].message.content' 2>/dev/null)

if [[ -n "$ROUTER_RESPONSE" ]]; then
  echo -e "  ${GREEN}✓${NC} Router API: $ROUTER_RESPONSE"
else
  echo -e "  ${RED}✗${NC} Router API failed"
fi

# 2. Test Runtime API
echo ""
echo -e "${BLUE}2. Testing Runtime API...${NC}"
RUNTIME_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3003/api/health)
if [ "$RUNTIME_STATUS" == "200" ]; then
  echo -e "  ${GREEN}✓${NC} Runtime API is healthy"
else
  echo -e "  ${RED}✗${NC} Runtime API returned status: $RUNTIME_STATUS"
fi

# 3. Test Chat UI
echo ""
echo -e "${BLUE}3. Testing Chat UI...${NC}"
CHAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3081)
if [ "$CHAT_STATUS" == "200" ]; then
  echo -e "  ${GREEN}✓${NC} Chat UI is accessible"
  echo "  Login: http://localhost:3081"
  echo "  Email: hattori@hanzo.ai"
  echo "  Password: hanzo123"
else
  echo -e "  ${RED}✗${NC} Chat UI returned status: $CHAT_STATUS"
fi

# 4. Test Services Hub
echo ""
echo -e "${BLUE}4. Testing Services Hub...${NC}"
SERVICES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
if [ "$SERVICES_STATUS" == "200" ]; then
  echo -e "  ${GREEN}✓${NC} Services Hub is healthy"
else
  echo -e "  ${RED}✗${NC} Services Hub returned status: $SERVICES_STATUS"
fi

# 5. List Available Models
echo ""
echo -e "${BLUE}5. Available Models via Router:${NC}"
curl -s -X GET http://localhost:4000/v1/models \
  -H "Authorization: Bearer sk-router-master-hanzo" 2>/dev/null \
  | jq -r '.data[].id' 2>/dev/null | grep -E "(gpt|claude|gemini|llama|mixtral)" | head -10 | while read model; do
  echo "  - $model"
done

# 6. Check API Keys
echo ""
echo -e "${BLUE}6. Configured API Providers:${NC}"
docker exec hanzo-router env | grep -E "API_KEY" | grep -v "=$" | cut -d'=' -f1 | sort -u | while read key; do
  echo -e "  ${GREEN}✓${NC} $key configured"
done

echo ""
echo -e "${BLUE}Integration Summary:${NC}"
echo "- Chat uses Router for all LLM calls"
echo "- Router has access to OpenAI, Anthropic, Google, Groq models"  
echo "- Runtime provides code execution capabilities"
echo "- Services Hub orchestrates inter-service communication"
echo "- All services are containerized and networked together"