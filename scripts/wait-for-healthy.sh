#!/bin/bash
# Script to wait for all services to be healthy

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Waiting for services to be healthy...${NC}"

# Maximum wait time (in seconds)
MAX_WAIT=300
WAIT_INTERVAL=5
ELAPSED=0

# Function to check if a service is healthy
check_service_health() {
    local service=$1
    docker compose ps --format json "$service" 2>/dev/null | grep -q '"Health":"healthy"'
}

# Get list of services with health checks
SERVICES=$(docker compose ps --services 2>/dev/null || echo "")

if [ -z "$SERVICES" ]; then
    echo -e "${RED}No services found. Make sure docker compose is running.${NC}"
    exit 1
fi

# Wait for each service
while [ $ELAPSED -lt $MAX_WAIT ]; do
    ALL_HEALTHY=true
    
    for service in $SERVICES; do
        if docker compose ps --format json "$service" 2>/dev/null | grep -q '"Health"'; then
            if ! check_service_health "$service"; then
                ALL_HEALTHY=false
                echo -e "${YELLOW}Waiting for $service to be healthy...${NC}"
            fi
        fi
    done
    
    if [ "$ALL_HEALTHY" = true ]; then
        echo -e "${GREEN}All services are healthy!${NC}"
        exit 0
    fi
    
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

echo -e "${RED}Timeout waiting for services to be healthy after ${MAX_WAIT} seconds${NC}"
exit 1