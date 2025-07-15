#!/bin/bash

# Demo: Hanzo Chat with Router Integration
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

# Main demo
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      HANZO CHAT + ROUTER INTEGRATION DEMO             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This demo shows Hanzo Chat connected to the local Router"
echo ""

header "1. CHECKING PREREQUISITES"

# Check if Router is running
if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/health >/dev/null; then
    log "✅ Router is running on port 4000"
else
    error "Router not running. Starting it..."
    cd /Users/z/work/hanzo/llm
    llm --host 0.0.0.0 --port 4000 --config config.yaml > /tmp/router.log 2>&1 &
    ROUTER_PID=$!
    sleep 10
fi

# Check infrastructure
if docker ps | grep -q hanzo-mongodb; then
    log "✅ MongoDB is running (required for Chat)"
else
    error "MongoDB not running. Please run: make start"
    exit 1
fi

header "2. CONFIGURING HANZO CHAT"

# Create environment configuration for Chat
cat > /Users/z/work/hanzo/chat2/.env.local << 'EOF'
# Hanzo Chat Configuration

# Use local Router
HANZO_API_KEY=sk-hanzo-master
HANZO_API_BASE_URL=http://localhost:4000

# Default to Hanzo endpoints
ENDPOINTS=hanzo

# Enable MCP
MCP_ENABLED=true

# MongoDB for chat storage
MONGO_URI=mongodb://hanzo:hanzo123@localhost:27017/hanzochat?authSource=admin

# Session secret
CREDS_KEY=hanzo-chat-secret-key-12345
JWT_SECRET=hanzo-jwt-secret-key-12345

# Domain
DOMAIN_CLIENT=http://localhost:3080
DOMAIN_SERVER=http://localhost:3080

# Branding
APP_TITLE=Hanzo Chat
HELP_AND_FAQ_URL=https://hanzo.ai/help

# Enable all features
REGISTRATION=true
SOCIAL_LOGIN_ENABLED=false
EOF

log "✅ Created chat configuration"

header "3. SETTING UP CHAT CONFIGURATION"

# Create chat.yaml with local Router
cat > /Users/z/work/hanzo/chat2/chat.yaml << 'EOF'
# Hanzo Chat Configuration
version: 1.1.0

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

# Endpoints configuration
endpoints:
  hanzo:
    baseURL: "http://localhost:4000/v1"
    models:
      default: ["gpt-3.5-turbo", "gpt-4", "claude-3-opus", "claude-3-sonnet"]
      fetch: true
    titleModel: "gpt-3.5-turbo"
    titleMethod: "completion"
    summarize: true
    summaryModel: "gpt-3.5-turbo"
    dropParams: []
    addParams:
      safe_prompt: false

# Model configuration
models:
  hanzo: true

# File configuration
fileConfig:
  endpoints:
    hanzo:
      fileLimit: 5
      fileSizeLimit: 10
      totalSizeLimit: 50
      supportedMimeTypes:
        - "image/.*"
        - "application/pdf"
        - "text/.*"
  serverFileSizeLimit: 100
  avatarSizeLimit: 2

# MCP Servers
mcpServers:
  - name: hanzo-mcp
    transport:
      - type: stdio
        command: hanzo-mcp
    env: {}
    enabled: true

# Rate limiting
rateLimits:
  fileUploads:
    ipMax: 100
    ipWindowInMinutes: 60
    userMax: 50
    userWindowInMinutes: 60
  conversationsImport:
    ipMax: 100
    ipWindowInMinutes: 60
    userMax: 50
    userWindowInMinutes: 60
EOF

log "✅ Created chat.yaml configuration"

header "4. INSTALLING DEPENDENCIES"

cd /Users/z/work/hanzo/chat2

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    info "Installing dependencies..."
    npm install --legacy-peer-deps > /tmp/chat-install.log 2>&1 || {
        error "Failed to install dependencies"
        tail -20 /tmp/chat-install.log
        exit 1
    }
    log "✅ Dependencies installed"
else
    log "✅ Dependencies already installed"
fi

header "5. STARTING HANZO CHAT"

# Kill any existing chat processes
pkill -f "node.*chat2" 2>/dev/null || true

info "Starting Hanzo Chat server..."

# Start the chat server
NODE_ENV=development npm run backend:dev > /tmp/chat-backend.log 2>&1 &
CHAT_BACKEND_PID=$!

sleep 5

# Start the chat client
info "Starting Hanzo Chat client..."
npm run frontend:dev > /tmp/chat-frontend.log 2>&1 &
CHAT_FRONTEND_PID=$!

sleep 10

# Check if services started
if lsof -i :3080 >/dev/null && lsof -i :3090 >/dev/null; then
    log "✅ Hanzo Chat is running"
else
    error "Failed to start Hanzo Chat"
    echo "Backend log:"
    tail -20 /tmp/chat-backend.log
    echo "Frontend log:"
    tail -20 /tmp/chat-frontend.log
    exit 1
fi

header "6. TESTING INTEGRATION"

# Test Router models endpoint
info "Testing Router models endpoint..."
MODELS=$(curl -s -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/v1/models | jq -r '.data[].id' | head -5)
echo "Available models:"
echo "$MODELS" | sed 's/^/  - /'

# Test MCP servers
info "Testing MCP servers..."
MCP_SERVERS=$(curl -s -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/api/mcps | jq 'keys' | head -10)
echo "Available MCP servers:"
echo "$MCP_SERVERS"

# Test chat API health
info "Testing Chat API..."
if curl -sf http://localhost:3080/api/health; then
    log "✅ Chat API is healthy"
else
    warning "Chat API health check failed"
fi

header "7. DEMO COMPLETE"

echo ""
echo -e "${GREEN}Hanzo Chat is now running and connected to the local Router!${NC}"
echo ""
echo "Access points:"
echo "  • ${CYAN}Chat UI:${NC} http://localhost:3080"
echo "  • ${CYAN}Router API:${NC} http://localhost:4000"
echo "  • ${CYAN}Chat API:${NC} http://localhost:3080/api"
echo ""
echo "Features available:"
echo "  ✅ Chat with multiple AI models"
echo "  ✅ MCP tools integration"
echo "  ✅ File uploads and analysis"
echo "  ✅ Conversation history"
echo "  ✅ Model switching"
echo ""
echo "Default credentials:"
echo "  Router API Key: sk-hanzo-master"
echo ""
log "You can now open http://localhost:3080 in your browser!"
echo ""
echo "Press Ctrl+C to stop all services..."

# Keep running
trap "kill $CHAT_BACKEND_PID $CHAT_FRONTEND_PID $ROUTER_PID 2>/dev/null; exit" INT
wait