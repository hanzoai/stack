#!/bin/bash

# Production Deployment Script for Hanzo Stack
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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   error "Please do not run this script as root"
   exit 1
fi

# Configuration
DEPLOY_ENV=${1:-staging}
STACK_DIR="/opt/hanzo/stack"
CONFIG_DIR="/etc/hanzo"
LOG_DIR="/var/log/hanzo"
DATA_DIR="/var/lib/hanzo"

clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        HANZO STACK PRODUCTION DEPLOYMENT              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"

header "Pre-deployment Checks"

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker not installed"
    exit 1
else
    log "✅ Docker installed"
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose not installed"
    exit 1
else
    log "✅ Docker Compose installed"
fi

# Check system resources
MEM_TOTAL=$(free -g | awk '/^Mem:/{print $2}')
if [ "$MEM_TOTAL" -lt 8 ]; then
    warning "⚠️  System has less than 8GB RAM. Recommended: 16GB+"
else
    log "✅ System memory: ${MEM_TOTAL}GB"
fi

header "Creating Production Environment"

# Create directories
info "Creating directory structure..."
sudo mkdir -p "$STACK_DIR" "$CONFIG_DIR" "$LOG_DIR" "$DATA_DIR"
sudo chown -R $USER:$USER "$STACK_DIR" "$CONFIG_DIR" "$LOG_DIR" "$DATA_DIR"

# Copy stack files
info "Copying stack files..."
cp -r /Users/z/work/hanzo/stack/* "$STACK_DIR/" 2>/dev/null || true

# Generate production configs
header "Generating Production Configurations"

# Create production docker-compose
cat > "$STACK_DIR/docker-compose.prod.yml" << 'EOF'
version: '3.8'

services:
  # Reverse Proxy
  traefik:
    image: traefik:v3.0
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/certs:/certs
    networks:
      - hanzo-network

  # PostgreSQL with replication
  postgres-primary:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: hanzo
      POSTGRES_REPLICATION_MODE: master
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: ${DB_REPL_PASSWORD}
    volumes:
      - postgres_primary_data:/var/lib/postgresql/data
    networks:
      - hanzo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis with persistence
  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - hanzo-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MongoDB replica set
  mongodb:
    image: mongo:7
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: hanzo
    volumes:
      - mongodb_data:/data/db
    networks:
      - hanzo-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  # MinIO cluster
  minio:
    image: minio/minio:latest
    restart: always
    environment:
      MINIO_ROOT_USER: ${MINIO_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD}
    volumes:
      - minio_data:/data
    command: server /data --console-address ":9001"
    networks:
      - hanzo-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 5

  # LLM Router
  llm-router:
    image: hanzo/llm-router:latest
    restart: always
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres-primary:5432/hanzo
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      MASTER_KEY: ${LLM_MASTER_KEY}
      LOG_LEVEL: info
    volumes:
      - ./config/llm:/app/config
    networks:
      - hanzo-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.llm.rule=Host(`llm.${DOMAIN}`)"
      - "traefik.http.routers.llm.tls=true"
      - "traefik.http.services.llm.loadbalancer.server.port=4000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_primary_data:
  redis_data:
  mongodb_data:
  minio_data:

networks:
  hanzo-network:
    driver: bridge
EOF

# Create production environment file
cat > "$CONFIG_DIR/.env.prod" << EOF
# Production Environment Variables
DOMAIN=hanzo.ai
DEPLOY_ENV=production

# Database
DB_USER=hanzo_prod
DB_PASSWORD=$(openssl rand -base64 32)
DB_REPL_PASSWORD=$(openssl rand -base64 32)

# Redis
REDIS_PASSWORD=$(openssl rand -base64 32)

# MongoDB
MONGO_USER=hanzo_prod
MONGO_PASSWORD=$(openssl rand -base64 32)

# MinIO
MINIO_USER=hanzo_prod
MINIO_PASSWORD=$(openssl rand -base64 32)

# LLM
LLM_MASTER_KEY=$(openssl rand -base64 32)

# Monitoring
GRAFANA_PASSWORD=$(openssl rand -base64 32)
EOF

# Secure the env file
chmod 600 "$CONFIG_DIR/.env.prod"

header "Setting Up Monitoring"

# Create monitoring stack
cat > "$STACK_DIR/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    restart: always
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - hanzo-network

  grafana:
    image: grafana/grafana:latest
    restart: always
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - hanzo-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`metrics.${DOMAIN}`)"
      - "traefik.http.routers.grafana.tls=true"

  loki:
    image: grafana/loki:latest
    restart: always
    volumes:
      - loki_data:/loki
    networks:
      - hanzo-network

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
EOF

header "Creating Backup Script"

# Create backup script
cat > "$STACK_DIR/scripts/backup.sh" << 'EOF'
#!/bin/bash
# Automated backup script

BACKUP_DIR="/backup/hanzo/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
docker exec postgres-primary pg_dump -U $DB_USER hanzo | gzip > "$BACKUP_DIR/postgres.sql.gz"

# Backup MongoDB
docker exec mongodb mongodump --archive="$BACKUP_DIR/mongodb.archive" --gzip

# Backup MinIO
docker run --rm -v minio_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/minio.tar.gz /data

# Backup Redis
docker exec redis redis-cli -a $REDIS_PASSWORD --rdb /data/backup.rdb
docker cp redis:/data/backup.rdb "$BACKUP_DIR/redis.rdb"

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x "$STACK_DIR/scripts/backup.sh"

header "Creating Systemd Service"

# Create systemd service
sudo tee /etc/systemd/system/hanzo-stack.service > /dev/null << EOF
[Unit]
Description=Hanzo Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$STACK_DIR
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
Restart=on-failure
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

header "Deployment Commands"

echo -e "${BLUE}To deploy to production:${NC}"
echo ""
echo "1. Review and update configuration:"
echo "   vim $CONFIG_DIR/.env.prod"
echo ""
echo "2. Start the stack:"
echo "   cd $STACK_DIR"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "3. Enable auto-start:"
echo "   sudo systemctl enable hanzo-stack"
echo "   sudo systemctl start hanzo-stack"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status hanzo-stack"
echo "   docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "5. View logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "6. Setup automated backups:"
echo "   sudo crontab -e"
echo "   0 2 * * * $STACK_DIR/scripts/backup.sh"
echo ""

warning "⚠️  Important: Update passwords in $CONFIG_DIR/.env.prod before deploying!"
log "Production deployment preparation complete!"