#!/bin/bash

# Script to fix TypeScript errors in the Chat project
# Run this from the hanzo/chat directory

set -e

echo "=== Fixing TypeScript Errors in Chat Project ==="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
    echo "Error: This script must be run from the hanzo/chat directory"
    echo "Please run: cd /Users/z/work/hanzo/chat && ./fix-chat-typescript-errors.sh"
    exit 1
fi

echo "1. Checking for TypeScript errors..."
echo ""

# First, let's see the actual errors
npm run type-check || true

echo ""
echo "2. Looking for the MCP manager file..."
if [ -f "src/mcp/manager.ts" ]; then
    echo "Found: src/mcp/manager.ts"
    
    # Common fixes for MCPToolCallResponse type issues
    echo ""
    echo "3. Attempting to fix MCPToolCallResponse type issue..."
    
    # Check line 895 for the specific error
    sed -n '890,900p' src/mcp/manager.ts
    
    echo ""
    echo "Common fixes for MCPToolCallResponse type mismatches:"
    echo "- Ensure the return type matches the expected interface"
    echo "- Check if all required fields are present"
    echo "- Verify optional fields are marked with ?"
    echo ""
    
    # Backup the file first
    cp src/mcp/manager.ts src/mcp/manager.ts.backup
    
    # Common fix patterns for MCP type issues
    # This is a placeholder - actual fix depends on the specific error
    echo "Please manually review src/mcp/manager.ts around line 895"
    echo "Look for:"
    echo "  - Missing or incorrect type annotations"
    echo "  - Incorrect return statement structure"
    echo "  - Missing await keywords for async operations"
fi

echo ""
echo "4. Looking for math.ts file with eval warning..."
if [ -f "src/utils/math.ts" ]; then
    echo "Found: src/utils/math.ts"
    
    # Backup the file
    cp src/utils/math.ts src/utils/math.ts.backup
    
    echo ""
    echo "Common fixes for eval warnings:"
    echo "- Replace eval() with Function constructor"
    echo "- Use a safe math expression parser library"
    echo "- Implement a custom expression evaluator"
    echo ""
    
    # Show the current implementation
    echo "Current implementation:"
    grep -n "eval" src/utils/math.ts || true
fi

echo ""
echo "5. Installing type definitions if missing..."
npm install --save-dev @types/node @types/react @types/react-dom || true

echo ""
echo "6. Running TypeScript compiler again..."
npm run type-check || true

echo ""
echo "=== Manual Review Required ==="
echo ""
echo "Since I cannot directly modify the chat repository files from the stack directory,"
echo "please review the following files manually:"
echo ""
echo "1. src/mcp/manager.ts (line 895) - Fix MCPToolCallResponse type mismatch"
echo "   - Ensure the return type matches the expected interface"
echo "   - Check all required fields are present"
echo ""
echo "2. src/utils/math.ts - Replace eval() usage"
echo "   - Consider using Function constructor: new Function('return ' + expression)()"
echo "   - Or use a math expression parser library like mathjs"
echo ""
echo "Example fix for eval warning:"
echo "  // Instead of: eval(expression)"
echo "  // Use: new Function('return ' + expression)()"
echo "  // Or better: use a library like mathjs"
echo ""
echo "After making changes, run: npm run type-check"
echo ""