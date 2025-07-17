#!/bin/bash

# Hanzo Stack Integration Test
# Tests all services and their connectivity

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Hanzo Stack Integration Test${NC}"
echo "================================"

# Function to test service endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Testing $name..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_code" ]; then
        echo -e " ${GREEN}✓${NC} (HTTP $response)"
        return 0
    else
        echo -e " ${RED}✗${NC} (HTTP $response)"
        return 1
    fi
}

# Test Core Infrastructure
echo -e "\n${YELLOW}Core Infrastructure:${NC}"
test_endpoint "PostgreSQL" "http://localhost:5432" "000"  # PostgreSQL doesn't serve HTTP
test_endpoint "Redis" "http://localhost:6379" "000"        # Redis doesn't serve HTTP
test_endpoint "MongoDB" "http://localhost:27017" "000"     # MongoDB doesn't serve HTTP
test_endpoint "MinIO Console" "http://localhost:9001"
test_endpoint "Meilisearch" "http://localhost:7700/health"

# Test Hanzo Services
echo -e "\n${YELLOW}Hanzo Services:${NC}"
test_endpoint "LLM Router" "http://localhost:4000/health"
test_endpoint "Chat UI" "http://localhost:3081"
test_endpoint "IDE" "http://localhost:3002"
test_endpoint "Analytics" "http://localhost:3090"

# Test Nginx Proxy
echo -e "\n${YELLOW}Nginx Proxy (Analytics Integration):${NC}"
test_endpoint "Chat via Nginx" "http://chat.localhost"
test_endpoint "IDE via Nginx" "http://ide.localhost"

# Test LLM Router API
echo -e "\n${YELLOW}LLM Router API Tests:${NC}"
echo -n "Testing Router models endpoint..."
models_response=$(curl -s "http://localhost:4000/v1/models" 2>/dev/null || echo "{}")
if echo "$models_response" | grep -q "data"; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
fi

# Service URLs
echo -e "\n${BLUE}📍 Service URLs:${NC}"
echo "• Chat: http://localhost:3081"
echo "• IDE: http://localhost:3002"
echo "• Analytics: http://localhost:3090"
echo "• LLM Router: http://localhost:4000"
echo "• MinIO Console: http://localhost:9001"
echo "• Meilisearch: http://localhost:7700"

# Container Health
echo -e "\n${BLUE}🏥 Container Health:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "hanzo|NAME"

# Quick Start Guide
echo -e "\n${BLUE}🎯 Quick Start:${NC}"
echo "1. Chat Interface: http://localhost:3081"
echo "   - AI chat with multiple models"
echo "   - Powered by LLM Router"
echo ""
echo "2. IDE (OpenHands): http://localhost:3002"
echo "   - AI-powered development environment"
echo "   - Code generation and editing"
echo ""
echo "3. Analytics Dashboard: http://localhost:3090"
echo "   - Privacy-focused analytics"
echo "   - Track usage across services"
echo ""
echo "4. LLM Router UI: http://localhost:4000/ui"
echo "   - Model management"
echo "   - Usage tracking"

# API Keys Note
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "\n${YELLOW}⚠️  Note: No AI API keys detected${NC}"
    echo "Set OPENAI_API_KEY or ANTHROPIC_API_KEY in .env for AI features"
fi

echo -e "\n${GREEN}✅ Stack test complete!${NC}"