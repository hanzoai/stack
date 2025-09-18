#!/bin/bash
# Script to fix Analytics and IAM services

set -e

echo "🔧 Fixing Analytics and IAM Services"

# Stop existing containers if running
docker stop hanzo-analytics hanzo-iam 2>/dev/null || true
docker rm hanzo-analytics hanzo-iam 2>/dev/null || true

# Create databases if they don't exist
echo "📦 Creating databases..."
docker exec hanzo-postgres psql -U hanzo -c "CREATE DATABASE IF NOT EXISTS hanzo_analytics;" 2>/dev/null || true
docker exec hanzo-postgres psql -U hanzo -c "CREATE DATABASE IF NOT EXISTS hanzo_iam;" 2>/dev/null || true

# Start Analytics with proper configuration
echo "🚀 Starting Analytics service..."
docker run -d --name hanzo-analytics \
  --network hanzo-network \
  --platform linux/arm64 \
  -e DATABASE_URL="postgres://hanzo:hanzo123@hanzo-postgres:5432/hanzo_analytics?sslmode=disable" \
  -e SKIP_DB_CHECK=1 \
  -e NEXTAUTH_URL="http://localhost:3010" \
  -e NEXTAUTH_SECRET="your-nextauth-secret" \
  -e DISABLE_SIGNUPS=false \
  -p 3010:3000 \
  ghcr.io/hanzoai/analytics:latest

# Note: IAM (Casdoor) requires additional configuration
# Currently has authentication issues with PostgreSQL
# Can be run with MySQL or proper Casdoor config file

echo "✅ Analytics service started on port 3010"
echo "⚠️  IAM service requires additional Casdoor configuration"