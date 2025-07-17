#!/bin/bash
# Setup environment for Hanzo Stack

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up Hanzo Stack environment...${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo -e "${YELLOW}Creating .env from .env.example...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env file${NC}"
        echo -e "${YELLOW}Please edit .env and add your API keys${NC}"
    else
        echo -e "${YELLOW}Warning: No .env.example found${NC}"
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Create necessary directories
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p logs/{router,chat,cloud,search,app-builder}
mkdir -p data/{chat/uploads,postgres,mongodb,redis,minio}
mkdir -p config

# Create router config if not exists
if [ ! -f config/router-config.yaml ]; then
    echo -e "${YELLOW}Creating router config...${NC}"
    cat > config/router-config.yaml << 'EOF'
# Hanzo Router Configuration
general_settings:
  master_key: ${ROUTER_MASTER_KEY}
  database_url: ${DATABASE_URL}
  redis_url: ${REDIS_URL}
  
router_settings:
  routing_strategy: "simple_shuffle"
  num_retries: 2
  request_timeout: 600
  
model_list:
  - model_name: gpt-4
    litellm_params:
      model: openai/gpt-4
      api_key: ${OPENAI_API_KEY}
  
  - model_name: gpt-3.5-turbo
    litellm_params:
      model: openai/gpt-3.5-turbo
      api_key: ${OPENAI_API_KEY}
  
  - model_name: claude-3-opus
    litellm_params:
      model: anthropic/claude-3-opus-20240229
      api_key: ${ANTHROPIC_API_KEY}
  
  - model_name: claude-3-sonnet
    litellm_params:
      model: anthropic/claude-3-sonnet-20240229
      api_key: ${ANTHROPIC_API_KEY}
EOF
    echo -e "${GREEN}✓ Created router config${NC}"
fi

# Create router extensions if not exists
if [ ! -f config/router-extensions.py ]; then
    echo -e "${YELLOW}Creating router extensions...${NC}"
    cat > config/router-extensions.py << 'EOF'
# Hanzo Router Extensions
# Custom middleware and modifications

from fastapi import Request, Response
import time

async def hanzo_middleware(request: Request, call_next):
    """Add custom headers and logging"""
    start_time = time.time()
    
    response = await call_next(request)
    
    # Add custom headers
    response.headers["X-Powered-By"] = "Hanzo AI"
    response.headers["X-Process-Time"] = str(time.time() - start_time)
    
    return response

# Export middleware
middleware = hanzo_middleware
EOF
    echo -e "${GREEN}✓ Created router extensions${NC}"
fi

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"

# Check Docker Compose
if ! command -v docker compose &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Using docker-compose (legacy)${NC}"
        # Create alias for consistency
        alias docker compose='docker-compose'
    else
        echo -e "${RED}Docker Compose is not installed${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker Compose v2 is available${NC}"
fi

# Pull base images
echo -e "${BLUE}Pulling base images...${NC}"
docker pull postgres:16-alpine &
docker pull redis:7-alpine &
docker pull mongo:7 &
docker pull minio/minio:latest &
docker pull getmeili/meilisearch:v1.6 &
wait

echo -e "${GREEN}✓ Base images pulled${NC}"

# Create docker network if not exists
if ! docker network ls | grep -q hanzo-network; then
    echo -e "${BLUE}Creating Docker network...${NC}"
    docker network create hanzo-network
    echo -e "${GREEN}✓ Created hanzo-network${NC}"
else
    echo -e "${GREEN}✓ Docker network already exists${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit .env file with your API keys"
echo "2. Run 'make up' to start all services"
echo "3. Run 'make status' to check service health"
echo ""
echo -e "${YELLOW}For development mode with hot reload:${NC}"
echo "  make dev        # Run in foreground"
echo "  make dev-up     # Run in background"