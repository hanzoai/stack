#!/bin/bash

# Script to start the real Hanzo API service (LLM Gateway)
# This starts the actual Hanzo LLM proxy server from the llm directory

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
LLM_DIR="/Users/z/work/hanzo/llm"
VENV_PATH="$LLM_DIR/.venv"
PORT=${PORT:-4000}
HOST=${HOST:-0.0.0.0}
CONFIG_FILE=${CONFIG_FILE:-"$LLM_DIR/config.yaml"}

echo -e "${YELLOW}Starting Hanzo API (LLM Gateway) Service...${NC}"

# Check if LLM directory exists
if [ ! -d "$LLM_DIR" ]; then
    echo -e "${RED}Error: LLM directory not found at $LLM_DIR${NC}"
    exit 1
fi

cd "$LLM_DIR"

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating...${NC}"
    python3 -m venv "$VENV_PATH"
fi

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source "$VENV_PATH/bin/activate"

# Install dependencies if needed
if ! python -c "import llm" 2>/dev/null; then
    echo -e "${YELLOW}Installing LLM package and dependencies...${NC}"
    pip install -e ".[proxy]"
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Warning: Config file not found at $CONFIG_FILE${NC}"
    echo -e "${YELLOW}Using default configuration...${NC}"
fi

# Export environment variables
export LLM_MODE=${LLM_MODE:-"PRODUCTION"}
export DATABASE_URL=${DATABASE_URL:-"postgresql://hanzo:hanzo123@localhost:5432/hanzo"}
export REDIS_URL=${REDIS_URL:-"redis://localhost:6379"}

# Check if any API keys are set
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$TOGETHER_API_KEY" ]; then
    echo -e "${YELLOW}Warning: No API keys found in environment.${NC}"
    echo -e "${YELLOW}Set at least one of: OPENAI_API_KEY, ANTHROPIC_API_KEY, TOGETHER_API_KEY${NC}"
fi

# Start the LLM proxy server
echo -e "${GREEN}Starting LLM proxy server on $HOST:$PORT...${NC}"
echo -e "${GREEN}API will be available at: http://$HOST:$PORT${NC}"
echo -e "${GREEN}Health check endpoint: http://$HOST:$PORT/health${NC}"
echo -e "${GREEN}OpenAPI docs: http://$HOST:$PORT/docs${NC}"

# Run the server
if [ -f "$CONFIG_FILE" ]; then
    python -m llm.proxy.proxy_cli \
        --host "$HOST" \
        --port "$PORT" \
        --config "$CONFIG_FILE"
else
    python -m llm.proxy.proxy_cli \
        --host "$HOST" \
        --port "$PORT"
fi