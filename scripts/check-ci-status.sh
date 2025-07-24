#!/bin/bash

# Script to check CI/CD status for all Hanzo projects
set -e

PROJECTS=(
    "router"
    "chat"
    "analytics"
    "ide"
    "runtime"
    "iam"
    "search"
    "cloud"
    "agent"
    "flow"
    "mcp"
)

echo "🔍 Checking CI/CD Status for Hanzo Projects"
echo "=========================================="
echo ""

for project in "${PROJECTS[@]}"; do
    echo "📦 $project:"
    
    # Check if GitHub Actions workflows exist
    echo -n "  Workflows: "
    gh workflow list --repo "hanzoai/$project" 2>/dev/null | grep -E "(Build|Docker)" | head -3 || echo "❌ No workflows found"
    
    # Check latest workflow runs
    echo -n "  Latest run: "
    gh run list --repo "hanzoai/$project" --limit 1 2>/dev/null | tail -n +2 || echo "❌ No runs"
    
    # Check if Docker image exists
    echo -n "  Image: "
    docker pull "ghcr.io/hanzoai/$project:latest" 2>&1 | grep -E "(Status:|manifest)" | head -1 || echo "❌ Not available"
    
    echo ""
done

echo "✅ Status check complete!"
echo ""
echo "📊 Summary:"
echo "- Green checkmarks = workflow successful"
echo "- Yellow circles = workflow in progress"
echo "- Red X = workflow failed or not found"