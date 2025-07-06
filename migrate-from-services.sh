#!/bin/bash

# Migrate from Hanzo Services to Hanzo Stack
# This script helps transition from the services repository to the new stack repository

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Hanzo Services → Stack Migration Script${NC}"
echo ""

# Check if services directory exists
if [ -z "$1" ]; then
    echo -e "${RED}Usage: ./migrate-from-services.sh /path/to/services${NC}"
    exit 1
fi

SERVICES_PATH="$1"

if [ ! -d "$SERVICES_PATH" ]; then
    echo -e "${RED}Services directory not found: $SERVICES_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Migrating from: $SERVICES_PATH${NC}"

# Copy compose files if they exist
if [ -f "$SERVICES_PATH/docker-compose.mothership.yml" ]; then
    echo -e "${GREEN}✓ Found mothership compose file${NC}"
    cp "$SERVICES_PATH/docker-compose.mothership.yml" ./docker-compose.services-backup.yml
    echo -e "${YELLOW}  Backed up to docker-compose.services-backup.yml${NC}"
fi

# Copy environment files
if [ -f "$SERVICES_PATH/.env" ]; then
    echo -e "${GREEN}✓ Found .env file${NC}"
    cp "$SERVICES_PATH/.env" ./.env.services-backup
    echo -e "${YELLOW}  Backed up to .env.services-backup${NC}"
    
    # Merge with our .env.example
    if [ ! -f .env ]; then
        cp .env.example .env
        echo -e "${YELLOW}  Created .env from template${NC}"
    fi
fi

# Copy any custom scripts
if [ -d "$SERVICES_PATH/scripts" ]; then
    echo -e "${GREEN}✓ Found scripts directory${NC}"
    cp -r "$SERVICES_PATH/scripts" ./scripts-backup
    echo -e "${YELLOW}  Backed up to scripts-backup/${NC}"
fi

# Extract service configurations
echo ""
echo -e "${GREEN}Analyzing service configurations...${NC}"

# Parse the mothership file for custom configurations
if [ -f "$SERVICES_PATH/docker-compose.mothership.yml" ]; then
    echo -e "${YELLOW}Extracting custom service configurations...${NC}"
    
    # Create a migration report
    cat > migration-report.md << EOF
# Migration Report

## Services Found

EOF
    
    # Extract service names
    services=$(grep -E '^[[:space:]]*[[:alnum:]_-]+:' "$SERVICES_PATH/docker-compose.mothership.yml" | sed 's/://g' | sed 's/^[[:space:]]*//')
    
    for service in $services; do
        echo "- $service" >> migration-report.md
    done
    
    echo -e "${GREEN}✓ Created migration-report.md${NC}"
fi

# Check for data volumes
echo ""
echo -e "${GREEN}Checking for existing data volumes...${NC}"

volumes=$(docker volume ls --format "{{.Name}}" | grep -E "(services_|hanzo_)" || true)

if [ -n "$volumes" ]; then
    echo -e "${YELLOW}Found existing volumes:${NC}"
    echo "$volumes"
    echo ""
    echo -e "${YELLOW}To preserve data, you can rename volumes:${NC}"
    echo -e "${YELLOW}Example: docker volume create hanzo-stack_postgres_data${NC}"
    echo -e "${YELLOW}         docker run --rm -v services_postgres_data:/from -v hanzo-stack_postgres_data:/to alpine cp -av /from/. /to/${NC}"
fi

# Create start script
cat > start-stack.sh << 'EOF'
#!/bin/bash

# Start Hanzo Stack with data migration

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting Hanzo Stack...${NC}"

# Check environment
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env and configure${NC}"
    exit 1
fi

# Check for port conflicts
echo -e "${YELLOW}Checking ports...${NC}"
make check-ports

# Start core services first
echo -e "${GREEN}Starting core services...${NC}"
make up-core

# Wait for core services
echo -e "${YELLOW}Waiting for core services to be healthy...${NC}"
sleep 10

# Start remaining services
echo -e "${GREEN}Starting all services...${NC}"
make up

# Check health
echo -e "${GREEN}Checking service health...${NC}"
make health

echo -e "${GREEN}Hanzo Stack started!${NC}"
echo ""
echo -e "${YELLOW}Service URLs:${NC}"
echo "  Chat:     http://localhost:3081"
echo "  Search:   http://localhost:3000"
echo "  API:      http://localhost:8000"
echo "  MinIO:    http://localhost:9001"
echo ""
echo -e "${YELLOW}View logs: make logs${NC}"
EOF

chmod +x start-stack.sh

echo ""
echo -e "${GREEN}Migration preparation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and merge configurations:"
echo "   - Check .env.services-backup for any custom settings"
echo "   - Review docker-compose.services-backup.yml for custom services"
echo ""
echo "2. Stop services repository containers:"
echo "   cd $SERVICES_PATH && docker compose down"
echo ""
echo "3. (Optional) Migrate data volumes - see volume commands above"
echo ""
echo "4. Start the new stack:"
echo "   ./start-stack.sh"
echo ""
echo -e "${GREEN}The Hanzo Stack provides a cleaner, more maintainable structure${NC}"
echo -e "${GREEN}with better service organization and management commands.${NC}"