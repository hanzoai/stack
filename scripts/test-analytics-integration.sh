#!/bin/bash

# Hanzo Stack Analytics Integration Test
# Tests that analytics is properly integrated across all services

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Testing Hanzo Stack Analytics Integration..."

# Function to check if a service is healthy
check_service() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    echo -n "Checking $service..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e " ${RED}✗${NC}"
    return 1
}

# Function to check analytics script injection
check_analytics() {
    local service=$1
    local url=$2
    local website_id=$3
    
    echo -n "Checking analytics for $service..."
    
    response=$(curl -s "$url" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "hanzo.js" && echo "$response" | grep -q "$website_id"; then
        echo -e " ${GREEN}✓ Analytics script found${NC}"
        return 0
    else
        echo -e " ${RED}✗ Analytics script not found${NC}"
        return 1
    fi
}

# Start services if not running
echo "Starting services..."
docker compose up -d

# Wait for services to be healthy
echo -e "\nWaiting for services to be ready..."
check_service "PostgreSQL" "http://localhost:5432" || true
check_service "Router" "http://localhost:4000/health/liveliness"
check_service "Analytics" "http://localhost:3090/api/heartbeat"
check_service "Chat" "http://localhost:3081/api/health"
check_service "IDE" "http://localhost:3002/health"

# Test analytics integration via nginx
echo -e "\n📊 Testing Analytics Integration:"

# Check if nginx is running
if docker ps | grep -q "hanzo-nginx"; then
    echo -e "Nginx: ${GREEN}✓ Running${NC}"
    
    # Test each service through nginx
    check_analytics "Chat" "http://chat.localhost" "chat-hanzo-ai"
    check_analytics "IDE" "http://ide.localhost" "ide-hanzo-ai"
    check_analytics "Search" "http://search.localhost" "search-hanzo-ai"
    check_analytics "Flow" "http://flow.localhost" "flow-hanzo-ai"
    check_analytics "Cloud" "http://cloud.localhost" "cloud-hanzo-ai"
    check_analytics "App" "http://app.localhost" "app-hanzo-ai"
else
    echo -e "Nginx: ${YELLOW}⚠ Not running - analytics injection not available${NC}"
fi

# Check analytics dashboard
echo -e "\n📈 Analytics Dashboard:"
if curl -s -f "http://localhost:3090" > /dev/null 2>&1; then
    echo -e "Analytics dashboard available at: ${GREEN}http://localhost:3090${NC}"
else
    echo -e "Analytics dashboard: ${RED}Not accessible${NC}"
fi

# Test analytics API
echo -e "\n🔌 Testing Analytics API:"
test_event=$(cat <<EOF
{
  "type": "event",
  "payload": {
    "website": "test-hanzo-stack",
    "name": "integration-test",
    "data": {"test": true, "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
  }
}
EOF
)

if curl -s -X POST "http://localhost:3090/api/send" \
    -H "Content-Type: application/json" \
    -d "$test_event" > /dev/null 2>&1; then
    echo -e "Analytics API: ${GREEN}✓ Working${NC}"
else
    echo -e "Analytics API: ${RED}✗ Not working${NC}"
fi

# Summary
echo -e "\n📋 Summary:"
echo "- Analytics service is configured at http://localhost:3090"
echo "- Production analytics will be at https://a.hanzo.ai"
echo "- Analytics script: hanzo.js"
echo "- All services configured with unique website IDs"
echo -e "\n✅ Analytics integration test complete!"