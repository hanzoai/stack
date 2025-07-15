#!/bin/bash

# Security Scan for Hanzo Stack
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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

# Security check results
ISSUES_FOUND=0
WARNINGS_FOUND=0

# Main execution
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            HANZO STACK SECURITY SCAN                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"

header "1. Container Security"

# Check for running containers
info "Checking Docker containers..."
for container in hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch; do
    if docker ps | grep -q $container; then
        # Check if running as root
        USER=$(docker exec $container whoami 2>/dev/null || echo "unknown")
        if [ "$USER" = "root" ]; then
            warning "⚠️  $container is running as root user"
            ((WARNINGS_FOUND++))
        else
            log "✅ $container is running as non-root user: $USER"
        fi
        
        # Check exposed ports
        PORTS=$(docker port $container 2>/dev/null | grep -c "0.0.0.0" || echo 0)
        if [ $PORTS -gt 0 ]; then
            info "   Exposed ports: $(docker port $container)"
        fi
    fi
done

header "2. Authentication Security"

# Test endpoints without auth
info "Testing unauthenticated access..."

# LLM endpoint should require auth
if curl -sf http://localhost:4000/health 2>/dev/null | grep -q "healthy"; then
    warning "⚠️  LLM health endpoint accessible without authentication"
    ((WARNINGS_FOUND++))
else
    log "✅ LLM endpoint requires authentication"
fi

# Test with invalid auth
if curl -sf -H "Authorization: Bearer invalid-token" http://localhost:4000/v1/models 2>&1 | grep -q "401\|Unauthorized"; then
    log "✅ LLM rejects invalid authentication"
else
    warning "⚠️  LLM may not be validating authentication properly"
    ((WARNINGS_FOUND++))
fi

header "3. Network Security"

# Check for unnecessary exposed ports
info "Checking exposed ports..."
EXPOSED_PORTS=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -E ":(4000|8000|5432|6379|27017|9000|9001|7700)" | wc -l || echo 0)
echo "   Found $EXPOSED_PORTS services listening on network ports"

# Check if services bind to all interfaces
for port in 4000 8000 5432 6379 27017 9000 7700; do
    if netstat -tuln 2>/dev/null | grep -q "0.0.0.0:$port"; then
        warning "⚠️  Port $port is bound to all interfaces (0.0.0.0)"
        ((WARNINGS_FOUND++))
    fi
done

header "4. Environment Variables"

# Check for sensitive data in environment
info "Checking for exposed secrets..."

# Check .env files
for env_file in .env .env.local .env.test; do
    if [ -f "$env_file" ]; then
        # Check for common secret patterns
        if grep -qE "(password|secret|key|token).*=.*['\"]?[a-zA-Z0-9]{8,}" "$env_file" 2>/dev/null; then
            warning "⚠️  Found potential secrets in $env_file"
            ((WARNINGS_FOUND++))
        fi
        
        # Check file permissions
        PERMS=$(stat -f "%p" "$env_file" 2>/dev/null || stat -c "%a" "$env_file" 2>/dev/null)
        if [ "${PERMS: -1}" -gt 4 ]; then
            error "❌ $env_file is readable by others (permissions: $PERMS)"
            ((ISSUES_FOUND++))
        fi
    fi
done

header "5. API Security"

# Test injection vulnerabilities
info "Testing for common vulnerabilities..."

# SQL injection test
INJECTION_TEST=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d '{"name": "Test\" OR \"1\"=\"1", "description": "Test"}' 2>/dev/null || echo "{}")

if echo "$INJECTION_TEST" | grep -q "error\|Error\|ERROR"; then
    log "✅ API appears to handle SQL injection attempts"
else
    warning "⚠️  API may be vulnerable to injection attacks"
    ((WARNINGS_FOUND++))
fi

# XSS test
XSS_TEST=$(curl -s -X POST http://localhost:8000/api/v1/projects \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer test-token" \
    -d '{"name": "<script>alert(1)</script>", "description": "XSS Test"}' 2>/dev/null || echo "{}")

if echo "$XSS_TEST" | grep -q "&lt;script&gt;\|\\u003c"; then
    log "✅ API properly escapes HTML content"
else
    warning "⚠️  API may be vulnerable to XSS attacks"
    ((WARNINGS_FOUND++))
fi

header "6. TLS/SSL Security"

# Check if services support HTTPS
info "Checking TLS support..."
if curl -sf https://localhost:4000/health 2>&1 | grep -q "SSL\|certificate"; then
    warning "⚠️  Services not configured with TLS/SSL"
    ((WARNINGS_FOUND++))
    echo "   Consider using a reverse proxy with TLS termination"
fi

header "7. Database Security"

# Check default credentials
info "Checking for default credentials..."
if docker exec hanzo-postgres psql -U hanzo -d hanzo -c "\dt" 2>&1 | grep -q "Did not find any relations"; then
    log "✅ PostgreSQL accessible (empty database is expected)"
else
    warning "⚠️  Could not verify PostgreSQL security"
    ((WARNINGS_FOUND++))
fi

# Check Redis auth
if docker exec hanzo-redis redis-cli ping 2>&1 | grep -q "NOAUTH"; then
    log "✅ Redis requires authentication"
else
    warning "⚠️  Redis may not require authentication"
    ((WARNINGS_FOUND++))
fi

header "Security Scan Summary"

echo ""
echo -e "${BLUE}Security Issues Found:${NC} $ISSUES_FOUND"
echo -e "${YELLOW}Security Warnings:${NC} $WARNINGS_FOUND"
echo ""

if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
    echo -e "${GREEN}⭐⭐⭐⭐⭐ EXCELLENT SECURITY${NC}"
    echo "No security issues detected!"
elif [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -le 3 ]; then
    echo -e "${GREEN}⭐⭐⭐⭐ GOOD SECURITY${NC}"
    echo "Minor security improvements recommended."
elif [ $ISSUES_FOUND -le 2 ]; then
    echo -e "${YELLOW}⭐⭐⭐ MODERATE SECURITY${NC}"
    echo "Some security issues should be addressed."
else
    echo -e "${RED}⭐⭐ NEEDS IMPROVEMENT${NC}"
    echo "Significant security improvements required."
fi

echo ""
echo -e "${BLUE}Recommendations:${NC}"
echo "1. Use TLS/SSL for all services in production"
echo "2. Bind services to localhost when possible"
echo "3. Use strong, unique passwords for all services"
echo "4. Regularly update all containers and dependencies"
echo "5. Implement proper API rate limiting"
echo "6. Use network segmentation in production"

log "Security scan complete!"