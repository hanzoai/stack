#!/bin/bash

# Simple script to start the Hanzo API service using run_server.py
# This is a simplified version that uses the run_server.py wrapper

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
LLM_DIR="/Users/z/work/hanzo/llm"
RUN_SCRIPT="$LLM_DIR/run_server.py"

echo -e "${YELLOW}Starting Hanzo API Service (simplified)...${NC}"

# Check if LLM directory exists
if [ ! -d "$LLM_DIR" ]; then
    echo -e "${RED}Error: LLM directory not found at $LLM_DIR${NC}"
    exit 1
fi

# Check if run_server.py exists
if [ ! -f "$RUN_SCRIPT" ]; then
    echo -e "${RED}Error: run_server.py not found at $RUN_SCRIPT${NC}"
    exit 1
fi

cd "$LLM_DIR"

# Export environment variables
export LLM_MODE=${LLM_MODE:-"PRODUCTION"}
export DATABASE_URL=${DATABASE_URL:-"postgresql://hanzo:hanzo123@localhost:5432/hanzo"}
export REDIS_URL=${REDIS_URL:-"redis://localhost:6379"}

# Check if any API keys are set
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$TOGETHER_API_KEY" ]; then
    echo -e "${YELLOW}Warning: No API keys found in environment.${NC}"
    echo -e "${YELLOW}Set at least one of: OPENAI_API_KEY, ANTHROPIC_API_KEY, TOGETHER_API_KEY${NC}"
fi

echo -e "${GREEN}Starting LLM proxy server...${NC}"
echo -e "${GREEN}API will be available at: http://0.0.0.0:4000${NC}"
echo -e "${GREEN}Health check endpoint: http://0.0.0.0:4000/health${NC}"
echo -e "${GREEN}OpenAPI docs: http://0.0.0.0:4000/docs${NC}"

# Run the server using the wrapper script
if [ -n "$1" ] && [ "$1" == "--config" ] && [ -n "$2" ]; then
    python "$RUN_SCRIPT" --config "$2"
else
    python "$RUN_SCRIPT"
fi