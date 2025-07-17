#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Building and Pushing Hanzo Images${NC}"
echo "===================================="

# Services to build and push
SERVICES=(
    "analytics:../analytics:Dockerfile"
    "chat:../chat:docker/Dockerfile.hanzo"
    "ide:../ide:app/dev/containers/app/Dockerfile"
    "iam:../iam:Dockerfile"
)

# Build and push each service
for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service context dockerfile <<< "$service_info"
    
    echo -e "\n${YELLOW}Building $service...${NC}"
    
    if [ -f "$context/$dockerfile" ]; then
        # Build the image
        if docker build -t ghcr.io/hanzoai/$service:latest -f $context/$dockerfile $context; then
            echo -e "${GREEN}✓ Built $service${NC}"
            
            # Push the image
            echo -e "${YELLOW}Pushing $service...${NC}"
            if docker push ghcr.io/hanzoai/$service:latest; then
                echo -e "${GREEN}✓ Pushed $service${NC}"
            else
                echo -e "${RED}✗ Failed to push $service${NC}"
            fi
        else
            echo -e "${RED}✗ Failed to build $service${NC}"
        fi
    else
        echo -e "${RED}✗ Dockerfile not found: $context/$dockerfile${NC}"
    fi
done

# For router, we'll use the existing ghcr.io/hanzoai/llm image as base
echo -e "\n${YELLOW}Tagging router image...${NC}"
docker tag ghcr.io/hanzoai/llm:latest ghcr.io/hanzoai/router:latest
docker push ghcr.io/hanzoai/router:latest
echo -e "${GREEN}✓ Tagged and pushed router${NC}"

echo -e "\n${BLUE}🎉 Build and Push Complete!${NC}"