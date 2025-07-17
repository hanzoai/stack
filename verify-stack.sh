#!/bin/bash

echo "🚀 Hanzo Stack Verification"
echo "=========================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check function
check_service() {
    local name=$1
    local cmd=$2
    
    echo -n "Checking $name... "
    if eval $cmd > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

echo "📡 Service Health Checks:"
echo "------------------------"

# PostgreSQL
check_service "PostgreSQL" "PGPASSWORD=hanzo123 psql -h localhost -U hanzo -d hanzo -c 'SELECT 1' 2>/dev/null"

# Redis
check_service "Redis" "redis-cli -a hanzo123 ping 2>/dev/null | grep -q PONG"

# MongoDB
check_service "MongoDB" "mongosh --quiet --eval 'db.adminCommand({ping: 1})' mongodb://hanzo:hanzo123@localhost:27017/hanzo?authSource=admin 2>/dev/null | grep -q '{ ok: 1 }'"

# MinIO
check_service "MinIO API" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9000 | grep -q 403"

# MinIO Console
check_service "MinIO Console" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9001 | grep -q 200"

# Meilisearch
check_service "Meilisearch" "curl -s http://localhost:7700/health | grep -q available"

# Router
check_service "Router API" "curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/health | grep -q 401"

echo ""
echo "🌐 Web Interfaces:"
echo "-----------------"
echo "MinIO Console:     http://localhost:9001  (user: minioadmin, pass: minioadmin)"
echo "Meilisearch UI:    http://localhost:7700"
echo "Router API:        http://localhost:4000"

echo ""
echo "🔧 Connection Examples:"
echo "----------------------"
echo "PostgreSQL:  PGPASSWORD=hanzo123 psql -h localhost -U hanzo -d hanzo"
echo "Redis:       redis-cli -a hanzo123"
echo "MongoDB:     mongosh mongodb://hanzo:hanzo123@localhost:27017/hanzo?authSource=admin"

echo ""
echo "📊 Docker Status:"
echo "-----------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep hanzo

echo ""
echo "✅ Stack is ready for testing!"