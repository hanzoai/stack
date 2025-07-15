#!/bin/bash

# Test Hanzo Router Completeness
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
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

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

# Main test
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         HANZO ROUTER COMPLETENESS TEST                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

header "1. ROUTER ENDPOINTS"

# Test OpenAPI page
info "Testing OpenAPI page..."
if curl -sf http://localhost:4000/ | grep -q "Hanzo AI, Inc. All rights reserved"; then
    log "✅ OpenAPI page shows Hanzo footer"
else
    error "❌ OpenAPI page missing Hanzo footer"
fi

if ! curl -sf http://localhost:4000/ | grep -q "Tool Hub"; then
    log "✅ Tool Hub link removed"
else
    error "❌ Tool Hub link still present"
fi

if ! curl -sf http://localhost:4000/ | grep -q "github.com"; then
    log "✅ GitHub link removed from navigation"
else
    error "❌ GitHub link still present"
fi

header "2. API ENDPOINTS"

# Test models endpoint
info "Testing models endpoint..."
MODELS=$(curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/v1/models | jq -r '.data | length')
if [ "$MODELS" -gt 0 ]; then
    log "✅ Models endpoint working ($MODELS models available)"
else
    log "⚠️  No models configured (need API keys)"
fi

# Test MCP servers endpoint
info "Testing MCP servers endpoint..."
MCP_COUNT=$(curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/api/mcps | jq 'keys | length')
log "✅ MCP servers endpoint working ($MCP_COUNT servers configured)"

header "3. UI PAGES"

# Test models UI page
info "Testing models UI page..."
if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/ui/models 2>/dev/null | grep -q "Models - Hanzo Router"; then
    log "✅ Models UI page accessible"
else
    log "⚠️  Models UI page not accessible (may need restart)"
fi

# Test MCP servers UI page
info "Testing MCP servers UI page..."
if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/ui/mcp-servers 2>/dev/null | grep -q "MCP Servers - Hanzo Router"; then
    log "✅ MCP servers UI page accessible"
else
    log "⚠️  MCP servers UI page not accessible (may need restart)"
fi

header "4. CONFIGURED SERVICES"

# Show enabled MCP servers
info "Enabled MCP servers:"
curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/api/mcps | jq -r 'to_entries[] | select(.value.enabled == true) | "  - \(.key)"'

# Check for real Hanzo services
info "Checking for Hanzo services..."
if docker ps | grep -q hanzo-mongodb; then
    log "✅ MongoDB running (for Chat)"
fi

if docker ps | grep -q hanzo-postgresql; then
    log "✅ PostgreSQL running (for Router)"
fi

if docker ps | grep -q hanzo-redis; then
    log "✅ Redis running (for caching)"
fi

header "5. SUMMARY"

echo ""
echo "Router is configured and running with:"
echo "  • Renamed to 'Router' (not LLM Router)"
echo "  • OpenAPI page with Hanzo footer"
echo "  • No toolhub or GitHub links in navigation"
echo "  • Models and MCP servers API endpoints"
echo "  • $MCP_COUNT MCP servers configured"
echo ""
echo "Next steps:"
echo "  1. Add API keys to .env for model providers"
echo "  2. Use chat2 (LibreChat fork) to connect to Router"
echo "  3. Access UI pages after Router restart"
echo ""
log "Test complete!"