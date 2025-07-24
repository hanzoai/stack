#!/bin/bash

# Router-specific testing for Hanzo Stack
# Tests LLM gateway functionality

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROUTER_URL="http://localhost:4000"
ROUTER_KEY="sk-router-master-hanzo"

echo -e "${BLUE}=== Testing Hanzo Router (LLM Gateway) ===${NC}\n"

# Test health endpoints
echo -e "${YELLOW}Health Checks:${NC}"
echo -n "General health... "
if curl -s -f "$ROUTER_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

echo -n "Liveliness check... "
response=$(curl -s -w "\n%{http_code}" "$ROUTER_URL/health/liveliness" -H "Authorization: Bearer $ROUTER_KEY" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Test model listing
echo -e "\n${YELLOW}Model Availability:${NC}"
echo "Fetching available models..."
models=$(curl -s "$ROUTER_URL/v1/models" -H "Authorization: Bearer $ROUTER_KEY" | jq -r '.data[].id' 2>/dev/null || echo "")

if [ -n "$models" ]; then
    echo "Available models:"
    echo "$models" | while read -r model; do
        echo "  - $model"
    done
else
    echo -e "${RED}Failed to fetch models${NC}"
fi

# Test chat completion with different models
echo -e "\n${YELLOW}Chat Completion Tests:${NC}"

test_model() {
    local model=$1
    echo -n "Testing $model... "
    
    response=$(curl -s -X POST "$ROUTER_URL/v1/chat/completions" \
        -H "Authorization: Bearer $ROUTER_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful assistant.\"},
                {\"role\": \"user\", \"content\": \"Say 'Hello from Hanzo Router test' in exactly 5 words.\"}
            ],
            \"temperature\": 0,
            \"max_tokens\": 20
        }" 2>/dev/null)
    
    if echo "$response" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
        content=$(echo "$response" | jq -r '.choices[0].message.content')
        echo -e "${GREEN}✓${NC} Response: $content"
    else
        error=$(echo "$response" | jq -r '.error.message // .error // "Unknown error"' 2>/dev/null || echo "Failed to parse response")
        echo -e "${RED}✗${NC} Error: $error"
    fi
}

# Test available models
for model in "gpt-3.5-turbo" "gpt-4" "claude-3-haiku-20240307"; do
    test_model "$model"
done

# Test streaming
echo -e "\n${YELLOW}Streaming Test:${NC}"
echo -n "Testing streaming response... "

# Create a temporary file for the streaming response
temp_file=$(mktemp)

curl -s -X POST "$ROUTER_URL/v1/chat/completions" \
    -H "Authorization: Bearer $ROUTER_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Count from 1 to 3"}],
        "stream": true,
        "max_tokens": 20
    }' > "$temp_file" 2>/dev/null

if grep -q "data:" "$temp_file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Streaming works"
else
    echo -e "${RED}✗${NC} Streaming failed"
fi

rm -f "$temp_file"

# Test rate limiting
echo -e "\n${YELLOW}Rate Limiting Test:${NC}"
echo "Sending multiple requests..."

success_count=0
for i in {1..5}; do
    response=$(curl -s -w "\n%{http_code}" -X POST "$ROUTER_URL/v1/chat/completions" \
        -H "Authorization: Bearer $ROUTER_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hi"}],
            "max_tokens": 5
        }' 2>/dev/null)
    
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        ((success_count++))
    fi
done

echo "Successful requests: $success_count/5"

# Test UI availability
echo -e "\n${YELLOW}UI Availability:${NC}"
echo -n "Router UI... "
response=$(curl -s -w "\n%{http_code}" "$ROUTER_URL/ui" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
    echo -e "${GREEN}✓${NC} Available at $ROUTER_URL/ui"
else
    echo -e "${RED}✗${NC} Not accessible"
fi

echo -e "\n${GREEN}Router testing completed!${NC}"