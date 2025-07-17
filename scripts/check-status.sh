#!/bin/bash
# Script to check the status of all Hanzo services

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Hanzo Stack Status ===${NC}"
echo ""

# Function to check service status
check_service() {
    local service=$1
    local port=$2
    local health_endpoint=$3
    
    echo -n "Checking $service... "
    
    # Check if container is running
    if ! docker compose ps --services | grep -q "^$service$" 2>/dev/null; then
        echo -e "${RED}Container not found${NC}"
        return
    fi
    
    # Check container status
    STATUS=$(docker compose ps --format json "$service" 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$STATUS" != "running" ]; then
        echo -e "${RED}Container not running (Status: $STATUS)${NC}"
        return
    fi
    
    # Check health status if available
    HEALTH=$(docker compose ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$HEALTH" ]; then
        case "$HEALTH" in
            "healthy")
                echo -e "${GREEN}✓ Healthy${NC}"
                ;;
            "starting")
                echo -e "${YELLOW}⟳ Starting${NC}"
                ;;
            *)
                echo -e "${RED}✗ Unhealthy${NC}"
                ;;
        esac
    else
        # Try to check port if no health check
        if [ -n "$port" ] && nc -z localhost "$port" 2>/dev/null; then
            echo -e "${GREEN}✓ Running (port $port open)${NC}"
        else
            echo -e "${YELLOW}⚠ Running (no health check)${NC}"
        fi
    fi
}

echo -e "${BLUE}Core Infrastructure:${NC}"
check_service "postgres" 5432
check_service "redis" 6379
check_service "mongodb" 27017
check_service "minio" 9000
check_service "meilisearch" 7700

echo ""
echo -e "${BLUE}Hanzo Services:${NC}"
check_service "router" 4000 "/health"
check_service "chat" 3081 "/api/health"
check_service "cloud" 3001 "/api/health"
check_service "search" 3000 "/api/health"
check_service "app-builder" 3002 "/api/health"

echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo -e "  Router (LLM Gateway): ${GREEN}http://localhost:4000${NC}"
echo -e "  Chat Interface:       ${GREEN}http://localhost:3081${NC}"
echo -e "  Cloud Management:     ${GREEN}http://localhost:3001${NC}"
echo -e "  Search Engine:        ${GREEN}http://localhost:3000${NC}"
echo -e "  App Builder:          ${GREEN}http://localhost:3002${NC}"
echo -e "  MinIO Console:        ${GREEN}http://localhost:9001${NC}"
echo -e "  Meilisearch UI:       ${GREEN}http://localhost:7700${NC}"