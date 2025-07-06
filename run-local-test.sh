#!/bin/bash

# Run Hanzo Stack tests locally
# This script provides an easy way to test the stack on your local machine

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Hanzo Stack Local Test Runner${NC}"
echo "================================"

# Check if running on macOS and adjust for Docker Desktop
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}Detected macOS - adjusting for Docker Desktop${NC}"
    export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
fi

# Function to check Docker resources
check_docker_resources() {
    echo -e "\n${YELLOW}Checking Docker resources...${NC}"
    
    # Get Docker info
    DOCKER_MEM=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    DOCKER_MEM_GB=$((DOCKER_MEM / 1024 / 1024 / 1024))
    
    echo "Docker Memory: ${DOCKER_MEM_GB}GB"
    
    if [ "$DOCKER_MEM_GB" -lt 16 ]; then
        echo -e "${RED}WARNING: Docker has less than 16GB memory allocated${NC}"
        echo "Recommended: 32GB for full stack, 16GB minimum"
        echo "To increase: Docker Desktop → Preferences → Resources → Memory"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Menu
show_menu() {
    echo -e "\n${BLUE}What would you like to test?${NC}"
    echo "1) Quick Test - Start services and run health checks (5 min)"
    echo "2) Integration Test - Run full integration test suite (15 min)"
    echo "3) Unit Tests Only - Run unit tests without starting services (2 min)"
    echo "4) Load Test - Run performance tests (10 min)"
    echo "5) Single Service Test - Test one service in isolation"
    echo "6) Clean Environment - Stop all services and clean up"
    echo "0) Exit"
    echo
    read -p "Select option: " choice
}

# Quick test
run_quick_test() {
    echo -e "\n${GREEN}Running quick test...${NC}"
    ./test.sh quick
}

# Integration test
run_integration_test() {
    echo -e "\n${GREEN}Running integration tests...${NC}"
    ./test.sh integration
}

# Unit tests
run_unit_tests() {
    echo -e "\n${GREEN}Running unit tests...${NC}"
    ./test.sh unit
}

# Load test
run_load_test() {
    echo -e "\n${GREEN}Running load tests...${NC}"
    ./test.sh load
}

# Single service test
test_single_service() {
    echo -e "\n${BLUE}Available services:${NC}"
    echo "1) LLM Gateway"
    echo "2) Chat"
    echo "3) API"
    echo "4) Cloud (Langfuse)"
    echo "5) Search"
    echo "6) IAM"
    read -p "Select service to test: " service_choice
    
    case $service_choice in
        1)
            SERVICE="llm-gateway"
            PORT="4000"
            HEALTH_PATH="/health"
            ;;
        2)
            SERVICE="chat"
            PORT="3081"
            HEALTH_PATH="/api/health"
            ;;
        3)
            SERVICE="api"
            PORT="8000"
            HEALTH_PATH="/health"
            ;;
        4)
            SERVICE="cloud"
            PORT="3000"
            HEALTH_PATH="/api/health"
            ;;
        5)
            SERVICE="search"
            PORT="3000"
            HEALTH_PATH="/api/health"
            ;;
        6)
            SERVICE="iam"
            PORT="8000"
            HEALTH_PATH="/api/health"
            ;;
        *)
            echo "Invalid choice"
            return
            ;;
    esac
    
    echo -e "\n${GREEN}Testing $SERVICE service...${NC}"
    
    # Start dependencies
    case $SERVICE in
        llm-gateway)
            DEPS="postgres redis"
            ;;
        chat)
            DEPS="postgres redis mongodb llm-gateway"
            ;;
        api)
            DEPS="postgres redis minio"
            ;;
        cloud)
            DEPS="postgres redis clickhouse"
            ;;
        search)
            DEPS="postgres meilisearch"
            ;;
        iam)
            DEPS="postgres"
            ;;
    esac
    
    echo "Starting dependencies: $DEPS"
    docker compose --env-file .env.test up -d $DEPS
    sleep 10
    
    echo "Starting $SERVICE..."
    docker compose --env-file .env.test up -d $SERVICE
    sleep 20
    
    echo "Testing $SERVICE health..."
    if curl -f "http://localhost:$PORT$HEALTH_PATH"; then
        echo -e "\n${GREEN}✓ $SERVICE is healthy${NC}"
        
        # Run service-specific tests
        docker compose --env-file .env.test -f docker-compose.test.yml run --rm integration-tests \
            pytest "tests/integration/test_$SERVICE.py" -v
    else
        echo -e "\n${RED}✗ $SERVICE health check failed${NC}"
    fi
    
    read -p "Press enter to stop services..."
    docker compose --env-file .env.test down
}

# Clean environment
clean_environment() {
    echo -e "\n${YELLOW}Cleaning test environment...${NC}"
    docker compose --env-file .env.test down -v --remove-orphans
    docker compose -f docker-compose.mocks.yml down -v
    echo -e "${GREEN}Environment cleaned${NC}"
}

# Main loop
main() {
    check_docker_resources
    
    while true; do
        show_menu
        
        case $choice in
            1) run_quick_test ;;
            2) run_integration_test ;;
            3) run_unit_tests ;;
            4) run_load_test ;;
            5) test_single_service ;;
            6) clean_environment ;;
            0) 
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0 
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Press enter to continue...${NC}"
        read
    done
}

# Run main
main