#!/bin/bash

echo "🧪 Testing Hanzo Stack Restart"
echo "============================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Test function
test_service() {
    local name=$1
    local cmd=$2
    local expected=$3
    
    echo -n "Testing $name... "
    result=$(eval $cmd 2>&1)
    if [[ "$result" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
        return 1
    fi
}

echo "📦 Step 1: Taking stack down"
echo "----------------------------"
make down
sleep 5

echo ""
echo "📦 Step 2: Starting stack up"
echo "----------------------------"
make up &
UP_PID=$!

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

echo ""
echo "📦 Step 3: Testing services"
echo "---------------------------"

# Test PostgreSQL
test_service "PostgreSQL" "PGPASSWORD=hanzo123 psql -h localhost -U hanzo -d hanzo -c 'SELECT 1' -t" "1"

# Test Redis
test_service "Redis" "redis-cli -a hanzo123 ping" "PONG"

# Test MongoDB
test_service "MongoDB" "docker exec hanzo-mongodb mongosh --quiet --eval 'db.adminCommand({ping: 1})' 'mongodb://hanzo:hanzo123@localhost:27017/hanzo?authSource=admin' | grep ok" "ok: 1"

# Test MinIO
test_service "MinIO" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9000" "403"

# Test Meilisearch
test_service "Meilisearch" "curl -s http://localhost:7700/health | jq -r .status" "available"

# Test Router
test_service "Router" "curl -s http://localhost:4000/health/liveliness" "I'm alive!"

echo ""
echo "📊 Final Status"
echo "---------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep hanzo

echo ""
echo "✅ Stack restart test complete!"