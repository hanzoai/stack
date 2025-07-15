#!/bin/bash

# Load Testing for Hanzo Stack
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

# Configuration
CONCURRENT_USERS=${1:-10}
REQUESTS_PER_USER=${2:-10}
LLM_AUTH="Authorization: Bearer sk-hanzo-master"

# Results storage
declare -a RESPONSE_TIMES
declare -a SUCCESS_COUNT
declare -a FAILURE_COUNT

# Function to make a request and measure time
make_request() {
    local endpoint=$1
    local method=$2
    local data=$3
    local auth=$4
    
    local start=$(date +%s%N)
    
    if [ "$method" = "POST" ]; then
        if [ -n "$auth" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$endpoint" \
                -H "$auth" \
                -H "Content-Type: application/json" \
                -d "$data" 2>/dev/null || echo "000")
        else
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" 2>/dev/null || echo "000")
        fi
    else
        if [ -n "$auth" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" -H "$auth" "$endpoint" 2>/dev/null || echo "000")
        else
            response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
        fi
    fi
    
    local end=$(date +%s%N)
    local duration=$((($end - $start) / 1000000))
    
    echo "$response|$duration"
}

# Function to run user simulation
simulate_user() {
    local user_id=$1
    local requests=$2
    
    local successes=0
    local failures=0
    local total_time=0
    
    for i in $(seq 1 $requests); do
        # Randomly choose an endpoint to test
        case $((RANDOM % 4)) in
            0)
                # LLM Health check
                result=$(make_request "http://localhost:4000/health" "GET" "" "$LLM_AUTH")
                ;;
            1)
                # API Health check
                result=$(make_request "http://localhost:8000/health" "GET" "" "")
                ;;
            2)
                # LLM Chat completion
                data='{
                    "model": "gpt-3.5-turbo",
                    "messages": [{"role": "user", "content": "Quick test '${user_id}'-'${i}'"}],
                    "max_tokens": 10
                }'
                result=$(make_request "http://localhost:4000/chat/completions" "POST" "$data" "$LLM_AUTH")
                ;;
            3)
                # Create project
                data='{
                    "name": "Load Test Project '${user_id}'-'${i}'",
                    "description": "Load testing"
                }'
                result=$(make_request "http://localhost:8000/api/v1/projects" "POST" "$data" "Authorization: Bearer test-token")
                ;;
        esac
        
        IFS='|' read -r status duration <<< "$result"
        total_time=$((total_time + duration))
        
        if [ "$status" = "200" ] || [ "$status" = "201" ]; then
            ((successes++))
        else
            ((failures++))
        fi
        
        # Small random delay between requests
        sleep 0.$((RANDOM % 500))
    done
    
    echo "$user_id|$successes|$failures|$total_time"
}

# Main execution
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              HANZO STACK LOAD TEST                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"

header "Test Configuration"
echo "Concurrent Users: $CONCURRENT_USERS"
echo "Requests per User: $REQUESTS_PER_USER"
echo "Total Requests: $((CONCURRENT_USERS * REQUESTS_PER_USER))"

# Ensure services are running
header "Pre-test Verification"
if curl -sf -H "$LLM_AUTH" http://localhost:4000/health >/dev/null && \
   curl -sf http://localhost:8000/health >/dev/null; then
    log "✅ Services are ready"
else
    error "Services not running. Starting mock services..."
    # Start mock services if needed
    python /tmp/mock-llm-router.py > /tmp/llm-load.log 2>&1 &
    python /tmp/mock-api.py > /tmp/api-load.log 2>&1 &
    sleep 5
fi

# Run load test
header "Running Load Test"
info "Simulating $CONCURRENT_USERS concurrent users..."

# Create temp file for results
RESULTS_FILE="/tmp/load_test_results_$$.txt"

# Launch concurrent users
for user in $(seq 1 $CONCURRENT_USERS); do
    simulate_user $user $REQUESTS_PER_USER >> "$RESULTS_FILE" &
done

# Show progress
echo -n "Progress: "
while [ $(jobs -r | wc -l) -gt 0 ]; do
    echo -n "."
    sleep 1
done
echo " Done!"

# Wait for all users to complete
wait

# Analyze results
header "Test Results"

total_successes=0
total_failures=0
total_time=0
user_count=0

while IFS='|' read -r user_id successes failures time; do
    total_successes=$((total_successes + successes))
    total_failures=$((total_failures + failures))
    total_time=$((total_time + time))
    ((user_count++))
done < "$RESULTS_FILE"

# Calculate statistics
total_requests=$((total_successes + total_failures))
success_rate=$((total_successes * 100 / total_requests))
avg_time=$((total_time / total_requests))
requests_per_second=$((total_requests * 1000 / total_time))

echo -e "${BLUE}Total Requests:${NC} $total_requests"
echo -e "${GREEN}Successful:${NC} $total_successes"
echo -e "${RED}Failed:${NC} $total_failures"
echo -e "${YELLOW}Success Rate:${NC} ${success_rate}%"
echo ""
echo -e "${BLUE}Average Response Time:${NC} ${avg_time}ms"
echo -e "${BLUE}Requests per Second:${NC} $requests_per_second"

# Performance rating
header "Performance Rating"
if [ $success_rate -ge 99 ] && [ $avg_time -lt 100 ]; then
    echo -e "${GREEN}⭐⭐⭐⭐⭐ EXCELLENT${NC}"
    echo "The stack handles load exceptionally well!"
elif [ $success_rate -ge 95 ] && [ $avg_time -lt 500 ]; then
    echo -e "${GREEN}⭐⭐⭐⭐ VERY GOOD${NC}"
    echo "The stack performs well under load."
elif [ $success_rate -ge 90 ] && [ $avg_time -lt 1000 ]; then
    echo -e "${YELLOW}⭐⭐⭐ GOOD${NC}"
    echo "The stack handles load adequately."
else
    echo -e "${RED}⭐⭐ NEEDS IMPROVEMENT${NC}"
    echo "Consider optimizing for better performance."
fi

# Cleanup
rm -f "$RESULTS_FILE"
pkill -f "mock-llm-router.py" 2>/dev/null || true
pkill -f "mock-api.py" 2>/dev/null || true

echo ""
log "Load test complete!"