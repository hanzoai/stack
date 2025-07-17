#!/bin/bash
# Check for port conflicts

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Checking for port conflicts...${NC}"
echo ""

# Define ports to check
declare -A PORTS=(
    ["PostgreSQL"]=5432
    ["Redis"]=6379
    ["MongoDB"]=27017
    ["MinIO API"]=9000
    ["MinIO Console"]=9001
    ["Meilisearch"]=7700
    ["Router/LLM Gateway"]=4000
    ["Chat Interface"]=3081
    ["Cloud Management"]=3001
    ["Search Engine"]=3000
    ["App Builder"]=3002
    ["Adminer"]=8080
    ["Redis Commander"]=8081
    ["Mongo Express"]=8082
)

CONFLICTS=0

# Check each port
for service in "${!PORTS[@]}"; do
    port=${PORTS[$service]}
    echo -n "Checking port $port ($service)... "
    
    if lsof -i :$port >/dev/null 2>&1; then
        echo -e "${RED}✗ IN USE${NC}"
        echo -e "  Process using port $port:"
        lsof -i :$port | grep LISTEN | head -1
        CONFLICTS=$((CONFLICTS + 1))
    else
        echo -e "${GREEN}✓ Available${NC}"
    fi
done

echo ""
if [ $CONFLICTS -eq 0 ]; then
    echo -e "${GREEN}All ports are available!${NC}"
    exit 0
else
    echo -e "${RED}Found $CONFLICTS port conflicts${NC}"
    echo -e "${YELLOW}Stop the conflicting services or change the ports in your .env file${NC}"
    exit 1
fi