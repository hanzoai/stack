#!/bin/bash

# Hanzo Stack Status Check
# Shows the current state of all Hanzo services

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 HANZO AI STACK STATUS${NC}"
echo "=============================="

# Function to check service
check_service() {
    local name=$1
    local port=$2
    local url=$3
    
    container_status=$(docker ps --filter "name=$name" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    
    if [[ $container_status == *"Up"* ]]; then
        echo -e "${GREEN}✓${NC} $name: Running ($container_status)"
        if [ ! -z "$url" ]; then
            if curl -s -f "$url" > /dev/null 2>&1; then
                echo "  └─ Accessible at: $url"
            else
                echo -e "  └─ ${YELLOW}Starting up...${NC} $url"
            fi
        fi
    else
        echo -e "${RED}✗${NC} $name: Not running"
    fi
}

echo -e "\n${YELLOW}Core Infrastructure:${NC}"
check_service "hanzo-postgres" "5432"
check_service "hanzo-redis" "6379"
check_service "hanzo-mongodb" "27017"
check_service "hanzo-minio" "9000" "http://localhost:9001"
check_service "hanzo-meilisearch" "7700" "http://localhost:7700"

echo -e "\n${YELLOW}Hanzo AI Services:${NC}"
check_service "hanzo-router" "4000" "http://localhost:4000/health"
check_service "hanzo-chat" "3081" "http://localhost:3081"
check_service "hanzo-ide" "3002" "http://localhost:3002"
check_service "hanzo-analytics" "3090" "http://localhost:3090"
check_service "hanzo-search" "3000" "http://localhost:3000"
check_service "hanzo-cloud" "3001" "http://localhost:3001"
check_service "hanzo-iam" "8080" "http://localhost:8080"
check_service "hanzo-nginx" "80" "http://localhost"

echo -e "\n${YELLOW}Service URLs:${NC}"
echo "• Router (LLM Gateway): http://localhost:4000"
echo "• Chat: http://localhost:3081"
echo "• IDE: http://localhost:3002"
echo "• Analytics: http://localhost:3090"
echo "• Search: http://localhost:3000"
echo "• Cloud: http://localhost:3001"
echo "• IAM: http://localhost:8080"
echo "• MinIO Console: http://localhost:9001"

echo -e "\n${YELLOW}Docker Compose Status:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${BLUE}Build Logs:${NC}"
echo "To view build progress: docker compose logs -f"
echo "To view specific service: docker compose logs -f [service-name]"