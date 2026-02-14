#!/bin/bash

# Script to trigger GitHub Actions workflows for all projects
set -e

echo "🚀 Triggering GitHub Actions workflows..."
echo "========================================"
echo ""

# Projects with docker-publish.yml workflow
DOCKER_PUBLISH_PROJECTS=(
    "router"
    "chat"
    "agent"
    "flow"
    "mcp"
    "ide"
)

# Trigger docker-publish.yml workflows
for project in "${DOCKER_PUBLISH_PROJECTS[@]}"; do
    echo "📦 Triggering docker-publish.yml for $project..."
    gh workflow run docker-publish.yml --repo "hanzoai/$project" 2>/dev/null && echo "✅ Triggered" || echo "❌ Failed to trigger"
done

# Projects with specific workflow names
echo ""
echo "📦 Triggering specific workflows..."

# Analytics
gh workflow run "Build and Push Analytics" --repo "hanzoai/analytics" 2>/dev/null && echo "✅ Analytics triggered" || echo "❌ Analytics failed"

# Runtime
gh workflow run "Build and Push Runtime" --repo "hanzoai/runtime" 2>/dev/null && echo "✅ Runtime triggered" || echo "❌ Runtime failed"

# Search
gh workflow run "Build and Push Search" --repo "hanzoai/search" 2>/dev/null && echo "✅ Search triggered" || echo "❌ Search failed"

# Cloud
gh workflow run "Build and Push Cloud" --repo "hanzoai/cloud" 2>/dev/null && echo "✅ Cloud triggered" || echo "❌ Cloud failed"

# IAM
gh workflow run "Build and Push IAM" --repo "hanzo.ai/iam" 2>/dev/null && echo "✅ IAM triggered" || echo "❌ IAM failed"

echo ""
echo "✅ Workflow triggers complete!"
echo ""
echo "📊 Monitor progress at:"
echo "https://github.com/hanzoai/[project]/actions"
echo ""
echo "Wait 5-10 minutes for builds to complete, then run:"
echo "make build && make up"