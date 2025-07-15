#!/bin/bash

# Hanzo Stack Test Runner
# This script runs the complete test suite using proper environment isolation

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COMPOSE_FILE="docker-compose.yml"
TEST_COMPOSE_FILE="docker-compose.test.yml"
MOCK_COMPOSE_FILE="docker-compose.mocks.yml"
ENV_FILE=".env.test"

# Parse arguments
TEST_TYPE="${1:-all}"
VERBOSE="${2:-false}"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

cleanup() {
    log "Cleaning up test environment..."
    docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -f $TEST_COMPOSE_FILE -f $MOCK_COMPOSE_FILE down -v --remove-orphans
    rm -f test-results.xml test-coverage.xml
}

# Trap cleanup on exit
trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        error "Docker Compose v2 is not installed"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    # Check available memory
    AVAILABLE_MEM=$(docker info --format '{{.MemTotal}}')
    REQUIRED_MEM=$((16 * 1024 * 1024 * 1024)) # 16GB in bytes
    
    if [ "$AVAILABLE_MEM" -lt "$REQUIRED_MEM" ]; then
        warning "Docker has less than 16GB memory allocated. Tests may fail."
        warning "Current: $(($AVAILABLE_MEM / 1024 / 1024 / 1024))GB, Required: 16GB"
    fi
    
    log "Prerequisites check passed ✓"
}

# Setup test environment
setup_test_env() {
    log "Setting up test environment..."
    
    # Create test env file if it doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        error "Test environment file not found: $ENV_FILE"
        exit 1
    fi
    
    # Export test environment
    export COMPOSE_PROJECT_NAME=hanzo-stack-test
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # Create necessary directories
    mkdir -p test-results test-data/postgres test-data/mongodb mocks/oauth
    
    log "Test environment ready ✓"
}

# Start mock services
start_mocks() {
    log "Starting mock external services..."
    
    docker compose --env-file $ENV_FILE -f $MOCK_COMPOSE_FILE up -d
    
    # Wait for mocks to be ready
    info "Waiting for mock services to be healthy..."
    sleep 10
    
    # Verify mocks
    if curl -f http://localhost:8080/v1/models &>/dev/null; then
        log "Mock OpenAI ready ✓"
    else
        error "Mock OpenAI failed to start"
        return 1
    fi
    
    if curl -f http://localhost:8081/v1/messages &>/dev/null; then
        log "Mock Anthropic ready ✓"
    else
        error "Mock Anthropic failed to start"
        return 1
    fi
    
    log "All mock services started ✓"
}

# Start core services
start_core() {
    log "Starting core infrastructure services..."
    
    docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d \
        postgres redis minio mongodb meilisearch clickhouse
    
    # Wait for services
    info "Waiting for core services to be healthy..."
    ./scripts/wait-for-healthy.sh postgres redis minio mongodb meilisearch clickhouse
    
    log "Core services started ✓"
}

# Run database migrations
run_migrations() {
    log "Running database migrations..."
    
    # PostgreSQL migrations
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm api-migrate
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm cloud-migrate
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm iam-migrate
    
    log "Migrations completed ✓"
}

# Seed test data
seed_test_data() {
    log "Seeding test data..."
    
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm api-seed
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm cloud-seed
    
    log "Test data seeded ✓"
}

# Start application services
start_services() {
    log "Starting application services..."
    
    docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d \
        llm-gateway chat mcp agent api cloud iam search
    
    # Wait for services
    info "Waiting for application services to be healthy..."
    ./scripts/wait-for-healthy.sh llm-gateway chat api cloud iam search
    
    log "Application services started ✓"
}

# Run unit tests
run_unit_tests() {
    log "Running unit tests..."
    
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm integration-tests \
        pytest tests/unit/ -v --junit-xml=/test-results/unit-tests.xml
    
    log "Unit tests completed ✓"
}

# Run integration tests
run_integration_tests() {
    log "Running integration tests..."
    
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm integration-tests \
        pytest tests/integration/ -v --junit-xml=/test-results/integration-tests.xml
    
    log "Integration tests completed ✓"
}

# Run load tests
run_load_tests() {
    log "Running load tests..."
    
    docker compose --env-file $ENV_FILE -f $TEST_COMPOSE_FILE run --rm k6 \
        run /scripts/llm-gateway-load.js --out json=/test-results/load-test.json
    
    log "Load tests completed ✓"
}

# Run security tests
run_security_tests() {
    log "Running security tests..."
    
    # Run OWASP ZAP scans
    docker run --rm -v $(pwd):/zap/wrk/:rw \
        --network hanzo-stack-test_hanzo \
        owasp/zap2docker-stable zap-baseline.py \
        -t http://api:8000 -r security-report.html || true
    
    log "Security tests completed ✓"
}

# Health check all services
health_check() {
    log "Running health checks..."
    
    local services=("api:8000/health" "cloud:3000/api/health" "chat:3081/api/health" 
                   "llm-gateway:4000/health" "search:3000/api/health" "iam:8000/api/health")
    
    for service in "${services[@]}"; do
        if docker compose --env-file $ENV_FILE exec -T integration-tests \
            curl -f "http://$service" &>/dev/null; then
            log "$service ✓"
        else
            error "$service ✗"
        fi
    done
}

# Main test execution
main() {
    log "Starting Hanzo Stack Test Suite"
    log "Test type: $TEST_TYPE"
    
    check_prerequisites
    setup_test_env
    
    case "$TEST_TYPE" in
        "all")
            start_mocks
            start_core
            run_migrations
            seed_test_data
            start_services
            health_check
            run_unit_tests
            run_integration_tests
            run_load_tests
            run_security_tests
            ;;
        "unit")
            run_unit_tests
            ;;
        "integration")
            start_mocks
            start_core
            run_migrations
            seed_test_data
            start_services
            health_check
            run_integration_tests
            ;;
        "load")
            start_mocks
            start_core
            start_services
            run_load_tests
            ;;
        "security")
            start_core
            start_services
            run_security_tests
            ;;
        "quick")
            start_mocks
            start_core
            start_services
            health_check
            ;;
        *)
            error "Unknown test type: $TEST_TYPE"
            echo "Usage: $0 [all|unit|integration|load|security|quick] [verbose]"
            exit 1
            ;;
    esac
    
    log "Test suite completed successfully! ✓"
    
    # Generate test report
    if [ -d "test-results" ]; then
        log "Test results saved to test-results/"
        ls -la test-results/
    fi
}

# Run main
main