#!/bin/bash
# Hanzo Stack Quick Start Script

set -e

echo "=== Hanzo Stack Quick Start ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from example...${NC}"
    cp env.example .env
fi

# Auto-detect API keys from environment
echo "Checking for API keys..."
KEYS_FOUND=false

# Function to update .env with environment variable
update_env_var() {
    local var_name=$1
    local var_value=$2
    if [ -n "$var_value" ]; then
        # Update or add the variable in .env
        if grep -q "^${var_name}=" .env; then
            # Use | as delimiter since API keys may contain special chars
            sed -i "" "s|^${var_name}=.*|${var_name}=${var_value}|" .env
        else
            echo "${var_name}=${var_value}" >> .env
        fi
        echo -e "   ${GREEN}✓${NC} Found ${var_name}"
        KEYS_FOUND=true
    fi
}

# Check for API keys in environment
if [ -n "$OPENAI_API_KEY" ]; then
    update_env_var "OPENAI_API_KEY" "$OPENAI_API_KEY"
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
    update_env_var "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"
fi

if [ -n "$TOGETHER_API_KEY" ]; then
    update_env_var "TOGETHER_API_KEY" "$TOGETHER_API_KEY"
fi

if [ -n "$GOOGLE_API_KEY" ]; then
    update_env_var "GOOGLE_API_KEY" "$GOOGLE_API_KEY"
fi

# Verify we have at least one API key
if ! $KEYS_FOUND; then
    echo -e "${RED}⚠️  No API keys found in environment!${NC}"
    echo "   Please set at least one of: OPENAI_API_KEY, ANTHROPIC_API_KEY"
    echo "   Example: export OPENAI_API_KEY=sk-..."
    exit 1
fi

echo -e "${BLUE}Starting Hanzo Stack...${NC}"
echo ""

# Start services
echo "1. Starting infrastructure services..."
docker compose up -d postgres redis mongodb minio meilisearch

echo ""
echo "2. Waiting for infrastructure to be ready..."
sleep 10

echo ""
echo "3. Starting AI services..."
docker compose up -d llm-gateway runtime services

echo ""
echo "4. Waiting for AI services to be ready..."
sleep 10

echo ""
echo "5. Starting Chat interface..."
docker compose up -d chat

echo ""
echo "6. Checking service health..."
sleep 5
make health || true

echo ""
echo -e "${GREEN}=== Hanzo Stack is starting! ===${NC}"
echo ""
echo "🌐 Access points:"
echo "   • Chat UI: http://localhost:3081"
echo "   • LLM Gateway: http://localhost:4000"
echo "   • Runtime API: http://localhost:3003"
echo "   • Services Hub: http://localhost:3000"
echo "   • MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
echo ""
echo "📊 Check status:"
echo "   • make ps          - List all services"
echo "   • make logs        - View logs"
echo "   • make health      - Check service health"
echo "   • make test        - Test connectivity"
echo "   • make test-runtime - Test code execution"
echo ""
echo "🛑 To stop:"
echo "   • make down        - Stop all services"
echo ""
echo -e "${YELLOW}Note: It may take a minute for all services to be fully ready.${NC}"
echo -e "${YELLOW}If Chat doesn't load immediately, wait 30 seconds and refresh.${NC}"