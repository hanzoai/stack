#!/bin/bash
# Setup development environment for Hanzo Stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
HANZO_DIR="$(dirname "$STACK_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Hanzo development environment...${NC}"

# Create .env file for chat2 if it doesn't exist
if [ ! -f "$HANZO_DIR/chat2/.env" ]; then
    echo -e "${YELLOW}Creating chat2 .env file...${NC}"
    cat > "$HANZO_DIR/chat2/.env" << 'EOF'
#=====================================================================#
#                  Hanzo Chat Development Configuration               #
#=====================================================================#

# Server Configuration
HOST=0.0.0.0
PORT=3081

# MongoDB - using Stack's MongoDB container
MONGO_URI=mongodb://localhost:27017/chat

# Domain Configuration
DOMAIN_CLIENT=http://localhost:3081
DOMAIN_SERVER=http://localhost:3081

# LLM Router Configuration (local development)
# This points to the local LLM Router running on port 4000
ENDPOINTS_HANZO_BASEURL=http://localhost:4000/v1
ENDPOINTS_HANZO_APIKEY=sk-hanzo-local-dev

# Disable brand mode for development
BRAND_MODE=false

# Enable all endpoints for development
ENDPOINTS_OPENAI=true
ENDPOINTS_ANTHROPIC=true
ENDPOINTS_HANZO=true

# Application Settings
APP_TITLE=Hanzo Chat (Dev)
NO_INDEX=true
DEBUG_LOGGING=true

# MCP Server Configuration
MCP_SERVERS_ENABLED=true

# Meilisearch Configuration
MEILI_HOST=http://localhost:7700
MEILI_MASTER_KEY=masterKey

# Session Secrets (development only - change in production!)
CREDS_KEY=abcdefghijklmnopqrstuvwxyz123456
CREDS_IV=1234567890123456
JWT_SECRET=hanzo-dev-jwt-secret-change-in-production
JWT_REFRESH_SECRET=hanzo-dev-refresh-secret-change-in-production

# Rate Limiting (relaxed for development)
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX_REQUESTS=1000

# File Upload Settings
FILE_SIZE_LIMIT=100
TOTAL_SIZE_LIMIT=500

# Development Features
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_PASSWORD_RESET=true
SHOW_MODEL_SETTINGS=true
EOF
    echo -e "${GREEN}✓ chat2 .env file created${NC}"
else
    echo -e "${YELLOW}chat2 .env file already exists${NC}"
fi

# Create development chat.yaml for chat2
echo -e "${YELLOW}Creating development chat.yaml...${NC}"
cat > "$HANZO_DIR/chat2/chat.yaml" << 'EOF'
# Hanzo Chat Configuration - Development Mode
version: 1.2.1

# Cache settings
cache: false

# Interface settings
interface:
  privacyPolicy:
    externalUrl: "https://hanzo.ai/privacy"
    openNewTab: true
  termsOfService:
    externalUrl: "https://hanzo.ai/terms"
    openNewTab: true

# Registration
registration:
  socialLogins: []

# Endpoints configuration - pointing to local Router
endpoints:
  custom:
    - name: "Hanzo"
      apiKey: "sk-hanzo-master"
      baseURL: "http://localhost:4000/v1"
      models:
        default: ["gpt-4o", "gpt-4o-mini", "claude-3-5-sonnet", "claude-3-opus"]
        fetch: true
      titleConvo: true
      titleModel: "gpt-4o-mini"
      modelDisplayLabel: "Hanzo"

# MCP Servers
mcpServers:
  hanzo_mcp:
    type: stdio
    command: uvx
    args: ["hanzo-mcp"]
    timeout: 60000
  filesystem:
    type: stdio  
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/Users/z/work/hanzo"]
    timeout: 60000

# File configuration
fileConfig:
  endpoints:
    custom:
      fileLimit: 10
      fileSizeLimit: 50
      totalSizeLimit: 200
      supportedMimeTypes:
        - "image/.*"
        - "application/pdf"
        - "text/.*"
        - "application/.*"
  serverFileSizeLimit: 100
  avatarSizeLimit: 2

# Rate limiting (relaxed for development)
rateLimits:
  fileUploads:
    ipMax: 1000
    ipWindowInMinutes: 60
    userMax: 500
    userWindowInMinutes: 60
  conversationsImport:
    ipMax: 1000
    ipWindowInMinutes: 60
    userMax: 500
    userWindowInMinutes: 60
EOF
echo -e "${GREEN}✓ Created development chat.yaml${NC}"

# Create development docker-compose override for Stack
cat > "$STACK_DIR/docker-compose.dev.yml" << 'EOF'
# Development override - only starts infrastructure, not apps
version: '3.8'

services:
  # Ensure infrastructure has proper dev settings
  mongodb:
    ports:
      - "27017:27017"
  
  redis:
    ports:
      - "6379:6379"
  
  postgres:
    ports:
      - "5432:5432"
  
  minio:
    ports:
      - "9000:9000"
      - "9001:9001"
  
  meilisearch:
    ports:
      - "7700:7700"
EOF

echo -e "${GREEN}✓ Created docker-compose.dev.yml${NC}"

# Check if LLM config exists
if [ ! -f "$HANZO_DIR/llm/config.yaml" ]; then
    echo -e "${YELLOW}Creating basic LLM Router config...${NC}"
    cat > "$HANZO_DIR/llm/config.yaml" << 'EOF'
general_settings:
  master_key: sk-hanzo-local-dev
  database_url: "postgresql://hanzo:hanzo123@localhost:5432/llm?sslmode=disable"
  redis_url: "redis://localhost:6379"
  
router_settings:
  model_group_alias:
    gpt-3.5-turbo: ["gpt-3.5-turbo-0125", "gpt-3.5-turbo-1106"]
    gpt-4: ["gpt-4-0125-preview", "gpt-4-1106-preview"]
    
litellm_settings:
  drop_params: true
  set_verbose: false
EOF
    echo -e "${GREEN}✓ Created basic LLM Router config${NC}"
fi

echo -e "${GREEN}Development environment setup complete!${NC}"
echo -e "${YELLOW}Run 'make dev' from the stack directory to start${NC}"