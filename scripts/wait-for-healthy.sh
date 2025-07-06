#!/bin/bash

# Wait for services to be healthy
# Usage: ./wait-for-healthy.sh service1 service2 ...

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

TIMEOUT=${TIMEOUT:-300}  # 5 minutes default
INTERVAL=${INTERVAL:-5}

services=("$@")

if [ ${#services[@]} -eq 0 ]; then
    echo -e "${RED}Error: No services specified${NC}"
    echo "Usage: $0 service1 service2 ..."
    exit 1
fi

echo -e "${GREEN}Waiting for services to be healthy...${NC}"

start_time=$(date +%s)

check_service() {
    local service=$1
    
    case "$service" in
        postgres)
            docker compose exec -T postgres pg_isready -U hanzo >/dev/null 2>&1
            ;;
        redis)
            docker compose exec -T redis redis-cli -a hanzo123 ping >/dev/null 2>&1
            ;;
        mongodb)
            docker compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1
            ;;
        minio)
            curl -f http://localhost:9000/minio/health/live >/dev/null 2>&1
            ;;
        meilisearch)
            curl -f http://localhost:7700/health >/dev/null 2>&1
            ;;
        clickhouse)
            docker compose exec -T clickhouse clickhouse-client -q "SELECT 1" >/dev/null 2>&1
            ;;
        llm-gateway)
            curl -f http://localhost:4000/health >/dev/null 2>&1
            ;;
        chat)
            curl -f http://localhost:3081/api/health >/dev/null 2>&1
            ;;
        api)
            curl -f http://localhost:8000/health >/dev/null 2>&1
            ;;
        cloud)
            curl -f http://localhost:3000 >/dev/null 2>&1
            ;;
        search)
            curl -f http://localhost:3000 >/dev/null 2>&1
            ;;
        iam)
            curl -f http://localhost:8000/api/health >/dev/null 2>&1
            ;;
        *)
            # Generic health check
            docker compose ps --format json "$service" | grep -q '"Health":"healthy"' >/dev/null 2>&1
            ;;
    esac
}

while true; do
    all_healthy=true
    
    for service in "${services[@]}"; do
        if check_service "$service"; then
            echo -e "${GREEN}✓${NC} $service is healthy"
        else
            echo -e "${YELLOW}⏳${NC} $service is not ready yet"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}All services are healthy!${NC}"
        exit 0
    fi
    
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $TIMEOUT ]; then
        echo -e "${RED}Timeout waiting for services to be healthy${NC}"
        docker compose ps
        exit 1
    fi
    
    echo -e "${YELLOW}Waiting $INTERVAL seconds before next check...${NC}"
    sleep $INTERVAL
done