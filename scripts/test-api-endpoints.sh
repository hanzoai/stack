#!/bin/bash

# API endpoint testing for Hanzo Stack
# Tests all exposed API endpoints

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROUTER_KEY="sk-router-master-hanzo"

echo -e "${BLUE}=== Testing Hanzo Stack API Endpoints ===${NC}\n"

# Function to test an endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    local data=$4
    local headers=$5
    
    echo -n "Testing $name... "
    
    if [ "$method" = "POST" ]; then
        if [ -n "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
                -H "Content-Type: application/json" \
                ${headers:+-H "$headers"} \
                -d "$data" 2>/dev/null || echo "000")
        else
            response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
                ${headers:+-H "$headers"} 2>/dev/null || echo "000")
        fi
    else
        response=$(curl -s -w "\n%{http_code}" "$url" \
            ${headers:+-H "$headers"} 2>/dev/null || echo "000")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "202" ] || [ "$http_code" = "204" ]; then
        echo -e "${GREEN}✓${NC} (HTTP $http_code)"
        return 0
    else
        echo -e "${RED}✗${NC} (HTTP $http_code)"
        return 1
    fi
}

# Router endpoints
echo -e "${YELLOW}Router API:${NC}"
test_endpoint "Health Check" "http://localhost:4000/health/liveliness"
test_endpoint "Models List" "http://localhost:4000/v1/models" "GET" "" "Authorization: Bearer $ROUTER_KEY"
test_endpoint "Chat Completion" "http://localhost:4000/v1/chat/completions" "POST" \
    '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hi"}],"max_tokens":10}' \
    "Authorization: Bearer $ROUTER_KEY"

# IDE endpoints
echo -e "\n${YELLOW}IDE API:${NC}"
test_endpoint "Health Check" "http://localhost:3002/health"
test_endpoint "API Info" "http://localhost:3002/api/info"
test_endpoint "Settings" "http://localhost:3002/api/settings"
test_endpoint "Agents List" "http://localhost:3002/api/agents"

# Chat endpoints
echo -e "\n${YELLOW}Chat API:${NC}"
test_endpoint "Health Check" "http://localhost:3081/api/health"

# Analytics endpoints
echo -e "\n${YELLOW}Analytics API:${NC}"
test_endpoint "Heartbeat" "http://localhost:3090/api/heartbeat"
test_endpoint "Send Event" "http://localhost:3090/api/send" "POST" \
    '{"website":"test","hostname":"test.local","language":"en-US","referrer":"","screen":"1920x1080","title":"Test","url":"/test","name":"pageview"}'

# Runtime endpoints
echo -e "\n${YELLOW}Runtime API:${NC}"
test_endpoint "Health Check" "http://localhost:8002/health"

# IAM endpoints
echo -e "\n${YELLOW}IAM API:${NC}"
test_endpoint "Health Check" "http://localhost:8080/api/health"

# MinIO endpoints
echo -e "\n${YELLOW}MinIO API:${NC}"
test_endpoint "Health Check" "http://localhost:9000/minio/health/live"

# Meilisearch endpoints
echo -e "\n${YELLOW}Meilisearch API:${NC}"
test_endpoint "Health Check" "http://localhost:7700/health"

echo -e "\n${GREEN}API endpoint testing completed!${NC}"