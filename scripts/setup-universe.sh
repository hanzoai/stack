#!/bin/bash
# Script to set up private universe repositories

set -e

echo "🌌 Setting up Private Universe Repositories"
echo "==========================================="
echo ""
echo "This script will help you set up the private production repositories."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI (gh) is not installed.${NC}"
    echo "Install it from: https://cli.github.com/"
    echo ""
    echo "Or run: brew install gh (macOS) / sudo apt install gh (Linux)"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Not authenticated with GitHub.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo "Choose which universe to set up:"
echo "1) Hanzo Universe (hanzoai/universe)"
echo "2) LuxFi Universe (luxfi/universe)"
echo "3) Both"
read -p "Enter choice (1-3): " choice

setup_hanzo_universe() {
    echo -e "${GREEN}Setting up Hanzo Universe...${NC}"

    # Create the repository
    echo "Creating private repository hanzoai/universe..."
    gh repo create hanzoai/universe \
        --private \
        --description "Private production universe - all Hanzo services, apps, and infrastructure" \
        --clone=false || echo "Repository may already exist"

    # Clone or set up local repo
    if [ -d "/home/z/work/hanzoai-universe" ]; then
        cd /home/z/work/hanzoai-universe
        git remote add origin git@github.com:hanzoai/universe.git 2>/dev/null || \
        git remote set-url origin git@github.com:hanzoai/universe.git

        echo "Pushing Hanzo Universe..."
        git push -u origin main
    else
        echo "Cloning universe template..."
        cd /home/z/work
        git clone git@github.com:hanzoai/stack.git hanzoai-universe
        cd hanzoai-universe
        git remote set-url origin git@github.com:hanzoai/universe.git

        # Add production configs
        cat > compose.production.yml << 'EOF'
# Production overrides
services:
  postgres:
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 4G

  router:
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
EOF

        git add .
        git commit -m "Initial universe setup from stack"
        git push -u origin main
    fi

    echo -e "${GREEN}✓ Hanzo Universe setup complete!${NC}"
}

setup_luxfi_universe() {
    echo -e "${GREEN}Setting up LuxFi Universe...${NC}"

    # Create the repository
    echo "Creating private repository luxfi/universe..."
    gh repo create luxfi/universe \
        --private \
        --description "Private production universe - LuxFi financial services and infrastructure" \
        --clone=false || echo "Repository may already exist"

    # Clone or set up local repo
    if [ -d "/home/z/work/luxfi-universe" ]; then
        cd /home/z/work/luxfi-universe
        git remote add origin git@github.com:luxfi/universe.git 2>/dev/null || \
        git remote set-url origin git@github.com:luxfi/universe.git

        echo "Pushing LuxFi Universe..."
        git push -u origin main
    else
        echo "Creating LuxFi universe from template..."
        cd /home/z/work
        mkdir -p luxfi-universe
        cd luxfi-universe
        git init

        # Copy base structure
        cp -r ../hanzoai-universe/.github .
        cp ../hanzoai-universe/README.md .

        # Customize for LuxFi
        sed -i 's/Hanzo/LuxFi/g' README.md
        sed -i 's/hanzoai/luxfi/g' README.md

        git add .
        git commit -m "Initial LuxFi universe setup"
        git remote add origin git@github.com:luxfi/universe.git
        git push -u origin main
    fi

    echo -e "${GREEN}✓ LuxFi Universe setup complete!${NC}"
}

# Execute based on choice
case $choice in
    1)
        setup_hanzo_universe
        ;;
    2)
        setup_luxfi_universe
        ;;
    3)
        setup_hanzo_universe
        setup_luxfi_universe
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Universe setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Add team members to the private repositories"
echo "2. Set up secrets management (git-crypt or HashiCorp Vault)"
echo "3. Configure CI/CD pipelines"
echo "4. Set up monitoring and alerting"
echo ""
echo "Repository URLs:"
echo "  Hanzo: https://github.com/hanzoai/universe"
echo "  LuxFi: https://github.com/luxfi/universe"
echo ""
echo "To sync from public stack:"
echo "  cd /path/to/universe"
echo "  git remote add public https://github.com/hanzoai/stack.git"
echo "  git fetch public"
echo "  git merge public/main --allow-unrelated-histories"