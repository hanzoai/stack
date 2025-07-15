#!/bin/bash

# Script to start the Hanzo API service using Docker
# This uses the official Hanzo API Docker image

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PORT=${PORT:-4000}
IMAGE=${HANZO_API_IMAGE:-"ghcr.io/hanzoai/api:latest"}

echo -e "${YELLOW}Starting Hanzo API Service via Docker...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Pull the latest image
echo -e "${GREEN}Pulling latest Hanzo API image...${NC}"
docker pull "$IMAGE"

# Check if container is already running
if docker ps | grep -q "hanzo-api"; then
    echo -e "${YELLOW}Stopping existing hanzo-api container...${NC}"
    docker stop hanzo-api
    docker rm hanzo-api
fi

# Prepare environment variables
ENV_VARS=""
if [ -n "$DATABASE_URL" ]; then
    ENV_VARS="$ENV_VARS -e DATABASE_URL=$DATABASE_URL"
else
    ENV_VARS="$ENV_VARS -e DATABASE_URL=postgresql://hanzo:hanzo123@host.docker.internal:5432/hanzo"
fi

if [ -n "$REDIS_URL" ]; then
    ENV_VARS="$ENV_VARS -e REDIS_URL=$REDIS_URL"
else
    ENV_VARS="$ENV_VARS -e REDIS_URL=redis://host.docker.internal:6379"
fi

# Add API keys if available
[ -n "$OPENAI_API_KEY" ] && ENV_VARS="$ENV_VARS -e OPENAI_API_KEY=$OPENAI_API_KEY"
[ -n "$ANTHROPIC_API_KEY" ] && ENV_VARS="$ENV_VARS -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
[ -n "$TOGETHER_API_KEY" ] && ENV_VARS="$ENV_VARS -e TOGETHER_API_KEY=$TOGETHER_API_KEY"

# Check if any API keys are set
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$TOGETHER_API_KEY" ]; then
    echo -e "${YELLOW}Warning: No API keys found in environment.${NC}"
    echo -e "${YELLOW}Set at least one of: OPENAI_API_KEY, ANTHROPIC_API_KEY, TOGETHER_API_KEY${NC}"
fi

# Run the container
echo -e "${GREEN}Starting Hanzo API container...${NC}"
docker run -d \
    --name hanzo-api \
    -p "$PORT:4000" \
    $ENV_VARS \
    -e PORT=4000 \
    -e ENVIRONMENT=production \
    "$IMAGE"

# Wait for the service to start
echo -e "${YELLOW}Waiting for API to be ready...${NC}"
sleep 5

# Check if container is running
if docker ps | grep -q "hanzo-api"; then
    echo -e "${GREEN}✓ Hanzo API is running!${NC}"
    echo -e "${GREEN}API available at: http://localhost:$PORT${NC}"
    echo -e "${GREEN}Health check: http://localhost:$PORT/health${NC}"
    echo -e "${GREEN}OpenAPI docs: http://localhost:$PORT/docs${NC}"
    echo ""
    echo -e "${YELLOW}To view logs: docker logs -f hanzo-api${NC}"
    echo -e "${YELLOW}To stop: docker stop hanzo-api${NC}"
else
    echo -e "${RED}Failed to start Hanzo API container${NC}"
    echo -e "${RED}Check logs with: docker logs hanzo-api${NC}"
    exit 1
fi