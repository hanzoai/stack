#!/bin/bash

# Hanzo Stack Integration Test Runner
# This script runs all integration tests for the Hanzo stack

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hanzo Stack Integration Tests ===${NC}"
echo

# Function to check if a service is ready
check_service() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=0
    
    echo -n "Checking $service..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    echo -e " ${RED}✗${NC}"
    return 1
}

# Function to run a test file
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .test.js)
    
    echo -e "\n${YELLOW}Running $test_name tests...${NC}"
    
    if npm test -- "$test_file" --verbose; then
        echo -e "${GREEN}✓ $test_name tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $test_name tests failed${NC}"
        return 1
    fi
}

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is required but not installed. Please install Node.js and npm.${NC}"
    exit 1
fi

# Install test dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing test dependencies...${NC}"
    npm install --save-dev jest node-fetch@2
fi

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"

services=(
    "PostgreSQL|localhost:5432"
    "Redis|localhost:6379"
    "MinIO|localhost:9000"
    "Meilisearch|http://localhost:7700/health"
    "Router|http://localhost:4000/health"
    "Chat|http://localhost:3081/api/health"
    "IDE|http://localhost:3002/health"
    "Analytics|http://localhost:3090/api/heartbeat"
    "Runtime|http://localhost:8002/health"
    "IAM|http://localhost:8080/api/health"
)

all_ready=true
for service_info in "${services[@]}"; do
    IFS='|' read -r service url <<< "$service_info"
    if ! check_service "$service" "$url"; then
        all_ready=false
    fi
done

if [ "$all_ready" = false ]; then
    echo -e "\n${RED}Some services are not ready. Please ensure all services are running.${NC}"
    echo -e "${YELLOW}You can start all services with: make up${NC}"
    exit 1
fi

echo -e "\n${GREEN}All services are ready!${NC}"

# Run integration tests
echo -e "\n${BLUE}Running integration tests...${NC}"

test_files=(
    "tests/integration/router.test.js"
    "tests/integration/ide.test.js"
    "tests/integration/full-stack.test.js"
)

failed_tests=0
passed_tests=0

for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        if run_test "$test_file"; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
    else
        echo -e "${YELLOW}Warning: $test_file not found, skipping...${NC}"
    fi
done

# Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "Total tests run: $((passed_tests + failed_tests))"
echo -e "${GREEN}Passed: $passed_tests${NC}"
echo -e "${RED}Failed: $failed_tests${NC}"

if [ $failed_tests -eq 0 ]; then
    echo -e "\n${GREEN}All integration tests passed! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please check the output above.${NC}"
    exit 1
fi