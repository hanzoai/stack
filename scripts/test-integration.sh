#!/bin/bash

# Integration test runner for Hanzo Stack
# This script runs comprehensive integration tests

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hanzo Stack Integration Tests ===${NC}"

# Change to stack directory
cd "$(dirname "$0")/.."

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is required but not installed. Please install Node.js and npm.${NC}"
    exit 1
fi

# Install test dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing test dependencies...${NC}"
    npm install --save-dev jest node-fetch@2 @jest/globals
fi

# Run the integration tests
echo -e "${BLUE}Running integration tests...${NC}"

# Check if test files exist
if [ -f "tests/integration/router.test.js" ] && [ -f "tests/integration/ide.test.js" ] && [ -f "tests/integration/full-stack.test.js" ]; then
    npm test
else
    echo -e "${YELLOW}Integration test files not found. Running basic connectivity tests...${NC}"
    
    # Basic connectivity tests
    echo -e "\n${BLUE}Testing service connectivity...${NC}"
    
    # Test router
    if curl -s -f http://localhost:4000/health > /dev/null 2>&1; then
        echo -e "Router: ${GREEN}✓${NC}"
    else
        echo -e "Router: ${RED}✗${NC}"
    fi
    
    # Test IDE
    if curl -s -f http://localhost:3002/health > /dev/null 2>&1; then
        echo -e "IDE: ${GREEN}✓${NC}"
    else
        echo -e "IDE: ${RED}✗${NC}"
    fi
    
    # Test Chat
    if curl -s -f http://localhost:3081/api/health > /dev/null 2>&1; then
        echo -e "Chat: ${GREEN}✓${NC}"
    else
        echo -e "Chat: ${RED}✗${NC}"
    fi
    
    # Test Analytics
    if curl -s -f http://localhost:3090/api/heartbeat > /dev/null 2>&1; then
        echo -e "Analytics: ${GREEN}✓${NC}"
    else
        echo -e "Analytics: ${RED}✗${NC}"
    fi
fi

echo -e "\n${GREEN}Integration tests completed!${NC}"