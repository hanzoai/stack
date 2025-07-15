#!/bin/bash

# Monitor Hanzo Stack Performance
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INTERVAL=${1:-5}  # Default 5 seconds
ITERATIONS=${2:-0}  # Default infinite (0)

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    clear
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    HANZO STACK PERFORMANCE MONITOR                 ${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to get container stats
get_container_stats() {
    local container=$1
    local stats=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}" $container 2>/dev/null || echo "0%|0MiB|0B")
    echo "$stats"
}

# Function to test endpoint performance
test_endpoint() {
    local name=$1
    local url=$2
    local auth=$3
    
    if [ -n "$auth" ]; then
        curl -o /dev/null -s -w "%{http_code}|%{time_total}" -H "Authorization: Bearer $auth" "$url" 2>/dev/null || echo "000|0"
    else
        curl -o /dev/null -s -w "%{http_code}|%{time_total}" "$url" 2>/dev/null || echo "000|0"
    fi
}

# Function to format time
format_time() {
    local time=$1
    if (( $(echo "$time < 0.1" | bc -l) )); then
        echo -e "${GREEN}${time}s${NC}"
    elif (( $(echo "$time < 0.5" | bc -l) )); then
        echo -e "${YELLOW}${time}s${NC}"
    else
        echo -e "${RED}${time}s${NC}"
    fi
}

# Function to format status
format_status() {
    local code=$1
    if [ "$code" = "200" ]; then
        echo -e "${GREEN}✅ OK${NC}"
    elif [ "$code" = "000" ]; then
        echo -e "${RED}❌ DOWN${NC}"
    else
        echo -e "${YELLOW}⚠️  $code${NC}"
    fi
}

# Main monitoring loop
count=0
while true; do
    header
    
    # Infrastructure Status
    echo -e "${CYAN}Infrastructure Services:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-20s %-15s %-20s %-15s\n" "Service" "CPU" "Memory" "Network"
    echo "─────────────────────────────────────────────────────────────────"
    
    for container in hanzo-postgres hanzo-redis hanzo-mongodb hanzo-minio hanzo-meilisearch; do
        if docker ps | grep -q $container; then
            stats=$(get_container_stats $container)
            IFS='|' read -r cpu mem net <<< "$stats"
            printf "%-20s %-15s %-20s %-15s\n" "$container" "$cpu" "$mem" "$net"
        else
            printf "%-20s ${RED}%-15s${NC}\n" "$container" "Not running"
        fi
    done
    
    echo ""
    
    # Service Performance
    echo -e "${CYAN}Service Performance:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-30s %-15s %-15s\n" "Endpoint" "Status" "Response Time"
    echo "─────────────────────────────────────────────────────────────────"
    
    # Test LLM endpoints
    result=$(test_endpoint "LLM Health" "http://localhost:4000/health" "sk-hanzo-master")
    IFS='|' read -r code time <<< "$result"
    printf "%-30s %-15s %-15s\n" "LLM Health" "$(format_status $code)" "$(format_time $time)"
    
    result=$(test_endpoint "LLM Models" "http://localhost:4000/v1/models" "sk-hanzo-master")
    IFS='|' read -r code time <<< "$result"
    printf "%-30s %-15s %-15s\n" "LLM Models" "$(format_status $code)" "$(format_time $time)"
    
    # Test API endpoints
    result=$(test_endpoint "API Health" "http://localhost:8000/health" "")
    IFS='|' read -r code time <<< "$result"
    printf "%-30s %-15s %-15s\n" "API Health" "$(format_status $code)" "$(format_time $time)"
    
    # Test infrastructure endpoints
    result=$(test_endpoint "MinIO" "http://localhost:9000/minio/health/live" "")
    IFS='|' read -r code time <<< "$result"
    printf "%-30s %-15s %-15s\n" "MinIO" "$(format_status $code)" "$(format_time $time)"
    
    result=$(test_endpoint "Meilisearch" "http://localhost:7700/health" "")
    IFS='|' read -r code time <<< "$result"
    printf "%-30s %-15s %-15s\n" "Meilisearch" "$(format_status $code)" "$(format_time $time)"
    
    echo ""
    
    # System Resources
    echo -e "${CYAN}System Resources:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    
    # CPU usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    echo -e "CPU Usage: ${YELLOW}$cpu_usage%${NC}"
    
    # Memory usage
    mem_info=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    mem_free=$((mem_info * 4096 / 1024 / 1024))
    echo -e "Free Memory: ${YELLOW}${mem_free}MB${NC}"
    
    # Disk usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "Disk Usage: ${YELLOW}$disk_usage${NC}"
    
    echo ""
    echo "─────────────────────────────────────────────────────────────────"
    echo -e "${GREEN}Refresh: ${INTERVAL}s | Press Ctrl+C to stop${NC}"
    
    # Check iteration limit
    ((count++))
    if [ "$ITERATIONS" -gt 0 ] && [ "$count" -ge "$ITERATIONS" ]; then
        echo ""
        log "Monitoring complete after $count iterations"
        break
    fi
    
    sleep $INTERVAL
done