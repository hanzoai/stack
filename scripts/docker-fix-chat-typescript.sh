#!/bin/bash

# Docker-based script to analyze and suggest fixes for Chat TypeScript errors
# This runs from the stack directory and uses Docker to access the chat source

set -e

echo "=== Analyzing Chat TypeScript Errors via Docker ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure we're in the stack directory
if [ ! -f "compose.yml" ]; then
    echo -e "${RED}Error: This script must be run from the hanzo/stack directory${NC}"
    exit 1
fi

echo "1. Building a temporary TypeScript analyzer container..."
cat > /tmp/analyze-chat-ts.dockerfile << 'EOF'
FROM node:20-alpine

WORKDIR /analyzer

# Install necessary tools
RUN apk add --no-cache bash git

# Create analysis script
RUN cat > /analyzer/analyze.sh << 'SCRIPT'
#!/bin/bash

cd /chat

echo "=== TypeScript Error Analysis ==="
echo ""

# Check if it's a valid chat project
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
    echo "Error: Invalid chat directory structure"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install --legacy-peer-deps || true
fi

echo ""
echo "Running TypeScript compilation check..."
npm run type-check 2>&1 | tee /tmp/ts-errors.log || true

echo ""
echo "=== Analyzing src/mcp/manager.ts ==="
if [ -f "src/mcp/manager.ts" ]; then
    echo "Line 895 context:"
    sed -n '890,900p' src/mcp/manager.ts | cat -n
    
    echo ""
    echo "Searching for MCPToolCallResponse usage:"
    grep -n "MCPToolCallResponse" src/mcp/manager.ts | head -10 || true
fi

echo ""
echo "=== Analyzing src/utils/math.ts ==="
if [ -f "src/utils/math.ts" ]; then
    echo "Eval usage:"
    grep -n "eval" src/utils/math.ts || echo "No direct eval usage found"
    
    echo ""
    echo "Full file content:"
    cat -n src/utils/math.ts | head -50
fi

echo ""
echo "=== Type Definition Check ==="
echo "Checking for MCP type definitions..."
find . -name "*.d.ts" -o -name "*.ts" | xargs grep -l "MCPToolCallResponse" 2>/dev/null | head -10 || true

echo ""
echo "=== Package.json Dependencies ==="
cat package.json | grep -A 20 '"dependencies"' | head -25

SCRIPT

chmod +x /analyzer/analyze.sh
CMD ["/analyzer/analyze.sh"]
EOF

echo ""
echo "2. Running analysis on chat codebase..."

# Build and run the analyzer
docker build -f /tmp/analyze-chat-ts.dockerfile -t chat-ts-analyzer .
docker run --rm -v /Users/z/work/hanzo/chat:/chat:ro chat-ts-analyzer > /tmp/chat-analysis.txt 2>&1

echo ""
echo "3. Analysis Results:"
echo "==================="
cat /tmp/chat-analysis.txt

echo ""
echo -e "${YELLOW}=== Recommended Fixes ===${NC}"
echo ""

echo -e "${GREEN}For MCPToolCallResponse Type Error:${NC}"
echo "1. Check if the interface definition matches the return value"
echo "2. Common fix pattern:"
echo ""
cat << 'TYPESCRIPT'
// Ensure your return matches the expected interface:
interface MCPToolCallResponse {
  success: boolean;
  result?: any;
  error?: string;
  metadata?: {
    toolName: string;
    timestamp: string;
    [key: string]: any;
  };
}

// Fix example:
return {
  success: true,
  result: processedData,
  metadata: {
    toolName: 'toolName',
    timestamp: new Date().toISOString()
  }
} as MCPToolCallResponse;
TYPESCRIPT

echo ""
echo -e "${GREEN}For eval() Warning:${NC}"
echo "1. Install mathjs: npm install mathjs @types/mathjs"
echo "2. Replace eval with safe alternative:"
echo ""
cat << 'TYPESCRIPT'
import { evaluate } from 'mathjs';

export function calculateExpression(expr: string): number {
  try {
    return evaluate(expr);
  } catch (error) {
    throw new Error('Invalid expression');
  }
}
TYPESCRIPT

echo ""
echo -e "${YELLOW}=== Next Steps ===${NC}"
echo "1. Navigate to the chat directory: cd /Users/z/work/hanzo/chat"
echo "2. Review the analysis output above"
echo "3. Apply the suggested fixes"
echo "4. Run: npm run type-check"
echo "5. Commit the fixes"

# Cleanup
docker rmi chat-ts-analyzer > /dev/null 2>&1 || true
rm -f /tmp/analyze-chat-ts.dockerfile

echo ""
echo -e "${GREEN}Analysis complete!${NC}"