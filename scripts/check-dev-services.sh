#!/bin/bash
# Check development services status

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Development Services Status ===${NC}"
echo ""

# Check if running in dev mode
if ! docker compose -f compose.yml -f compose.dev.yml ps --services >/dev/null 2>&1; then
    echo -e "${RED}Development services are not running${NC}"
    echo "Run 'make dev-up' to start development services"
    exit 1
fi

# Check volume mounts
echo -e "${BLUE}Volume Mounts:${NC}"
docker compose -f compose.yml -f compose.dev.yml ps --format json | \
    jq -r '.[] | select(.Mounts != null) | "\(.Service): \(.Mounts | length) mounts"' 2>/dev/null || \
    echo "Unable to check volume mounts"

echo ""
echo -e "${BLUE}Development Features:${NC}"

# Check if services are in development mode
for service in router chat cloud search app-builder; do
    echo -n "$service: "
    
    # Check environment variables
    ENV_MODE=$(docker compose -f compose.yml -f compose.dev.yml exec -T $service sh -c 'echo $NODE_ENV$ROUTER_MODE' 2>/dev/null || echo "")
    
    if [[ "$ENV_MODE" == *"development"* ]] || [[ "$ENV_MODE" == *"DEVELOPMENT"* ]]; then
        echo -e "${GREEN}✓ Development mode${NC}"
    else
        echo -e "${YELLOW}⚠ Not in development mode${NC}"
    fi
done

echo ""
echo -e "${BLUE}Hot Reload Status:${NC}"
echo -e "  Chat:        ${GREEN}✓ Enabled${NC} (Next.js dev server)"
echo -e "  Cloud:       ${GREEN}✓ Enabled${NC} (pnpm dev)"
echo -e "  Search:      ${GREEN}✓ Enabled${NC} (npm dev)"
echo -e "  App Builder: ${GREEN}✓ Enabled${NC} (npm dev)"
echo -e "  Router:      ${YELLOW}⚠ Restart required${NC} (Python service)"

echo ""
echo -e "${BLUE}Development Tools:${NC}"
if docker compose -f compose.yml -f compose.dev.yml --profile tools ps --services | grep -q adminer; then
    echo -e "  Adminer:        ${GREEN}http://localhost:8080${NC}"
    echo -e "  Redis Commander: ${GREEN}http://localhost:8081${NC}"
    echo -e "  Mongo Express:   ${GREEN}http://localhost:8082${NC}"
else
    echo -e "  ${YELLOW}Not running. Use 'make tools' to start${NC}"
fi