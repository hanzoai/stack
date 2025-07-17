#!/bin/bash
# Script to perform health checks on all Hanzo services

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Hanzo Stack Health Check ===${NC}"
echo ""

TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to perform health check
health_check() {
    local service=$1
    local url=$2
    local expected_status=${3:-200}
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Health check for $service... "
    
    # Check if service container exists
    if ! docker compose ps --services | grep -q "^$service$" 2>/dev/null; then
        echo -e "${RED}✗ Service not found${NC}"
        return
    fi
    
    # Try to hit the health endpoint
    if [ -n "$url" ]; then
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        
        if [ "$RESPONSE" = "$expected_status" ]; then
            echo -e "${GREEN}✓ OK (HTTP $RESPONSE)${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        elif [ "$RESPONSE" = "000" ]; then
            echo -e "${RED}✗ Connection failed${NC}"
        else
            echo -e "${RED}✗ Unexpected response (HTTP $RESPONSE)${NC}"
        fi
    else
        # For services without HTTP health check, just check if running
        STATUS=$(docker compose ps --format json "$service" 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
        if [ "$STATUS" = "running" ]; then
            echo -e "${GREEN}✓ Running${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${RED}✗ Not running${NC}"
        fi
    fi
}

# Database checks
echo -e "${BLUE}Database Services:${NC}"
health_check "postgres" ""
health_check "redis" ""
health_check "mongodb" ""

echo ""
echo -e "${BLUE}Storage Services:${NC}"
health_check "minio" "http://localhost:9000/minio/health/live"
health_check "meilisearch" "http://localhost:7700/health"

echo ""
echo -e "${BLUE}Application Services:${NC}"
health_check "router" "http://localhost:4000/health"
health_check "chat" "http://localhost:3081/api/health"
health_check "cloud" "http://localhost:3001/api/health"
health_check "search" "http://localhost:3000/api/health"
health_check "app-builder" "http://localhost:3002/api/health"

# Summary
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$((TOTAL_CHECKS - PASSED_CHECKS))${NC}"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}All health checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some health checks failed${NC}"
    exit 1
fi