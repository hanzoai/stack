# Chat TypeScript Error Fixes

## Overview

The Chat project (LibreChat fork with MCP integration) is experiencing TypeScript compilation errors that are causing CI failures:

1. **Type mismatch with MCPToolCallResponse** in `src/mcp/manager.ts` (line 895:32)
2. **Warning about eval usage** in `src/utils/math.ts`

## Error 1: MCPToolCallResponse Type Mismatch

### Common Causes

The MCPToolCallResponse type mismatch at line 895 typically occurs when:

1. The function return type doesn't match the expected MCPToolCallResponse interface
2. Required fields are missing from the response object
3. Field types don't match the interface definition
4. Async functions are missing proper Promise typing

### Likely Fix Patterns

```typescript
// Check if the MCPToolCallResponse interface expects:
interface MCPToolCallResponse {
  success: boolean;
  result?: any;
  error?: string;
  // ... other fields
}

// Common fix patterns:

// 1. Ensure all required fields are present
return {
  success: true,
  result: data,
  // Add any other required fields
} as MCPToolCallResponse;

// 2. For async functions, ensure proper Promise typing
async function handleToolCall(): Promise<MCPToolCallResponse> {
  try {
    const result = await someOperation();
    return {
      success: true,
      result
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// 3. If using a union type, ensure type narrowing
if (response.type === 'tool_call') {
  return response as MCPToolCallResponse;
}
```

### Debugging Steps

1. Check the MCPToolCallResponse interface definition
2. Verify all required fields are included in the return statement
3. Ensure proper type assertions or type guards are used
4. Check if async/await is properly handled

## Error 2: Eval Warning in math.ts

### Security Concern

The `eval()` function poses security risks as it executes arbitrary code. TypeScript and linters warn against its usage.

### Safe Alternatives

```typescript
// Option 1: Function Constructor (slightly safer than eval)
function evaluateMathExpression(expression: string): number {
  // Sanitize input first
  const sanitized = expression.replace(/[^0-9+\-*/().\s]/g, '');
  
  try {
    // Function constructor is marginally safer than eval
    return new Function('return ' + sanitized)();
  } catch (error) {
    throw new Error('Invalid math expression');
  }
}

// Option 2: Use a math expression parser library
import { evaluate } from 'mathjs'; // npm install mathjs

function evaluateMathExpression(expression: string): number {
  try {
    return evaluate(expression);
  } catch (error) {
    throw new Error('Invalid math expression');
  }
}

// Option 3: Build a simple math parser (safest)
function evaluateMathExpression(expression: string): number {
  // Implement a basic math parser for +, -, *, /
  // This is more work but completely safe
  const tokens = tokenize(expression);
  return parseExpression(tokens);
}

// Option 4: Use Web Workers for isolation (browser only)
function evaluateMathExpression(expression: string): Promise<number> {
  return new Promise((resolve, reject) => {
    const worker = new Worker('math-evaluator.js');
    worker.postMessage({ expression });
    worker.onmessage = (e) => resolve(e.data.result);
    worker.onerror = reject;
  });
}
```

### Recommended Solution

For the Chat application, I recommend using the `mathjs` library as it:
- Provides safe expression evaluation
- Supports complex mathematical operations
- Has TypeScript support
- Is well-maintained and widely used

```bash
# Install mathjs
npm install mathjs
npm install --save-dev @types/mathjs
```

## Implementation Guide

### Step 1: Fix MCPToolCallResponse Type

```typescript
// In src/mcp/manager.ts around line 895
// Locate the function causing the error and ensure proper typing

// Example fix:
async function processToolCall(
  tool: string,
  args: any
): Promise<MCPToolCallResponse> {
  try {
    // Process the tool call
    const result = await executeToolCall(tool, args);
    
    // Ensure the return matches MCPToolCallResponse
    return {
      success: true,
      result,
      toolName: tool,
      timestamp: new Date().toISOString()
    } as MCPToolCallResponse;
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      toolName: tool,
      timestamp: new Date().toISOString()
    } as MCPToolCallResponse;
  }
}
```

### Step 2: Replace eval() in math.ts

```typescript
// In src/utils/math.ts
import { evaluate, round } from 'mathjs';

export function calculateExpression(expression: string): number {
  try {
    // Use mathjs for safe evaluation
    const result = evaluate(expression);
    
    // Round to reasonable precision
    return round(result, 10);
  } catch (error) {
    console.error('Math evaluation error:', error);
    throw new Error('Invalid mathematical expression');
  }
}

// For simple expressions, you can also implement a whitelist approach
export function calculateSimpleExpression(expression: string): number {
  // Only allow numbers, operators, parentheses, and decimal points
  const allowedChars = /^[0-9+\-*/().\s]+$/;
  
  if (!allowedChars.test(expression)) {
    throw new Error('Invalid characters in expression');
  }
  
  try {
    // Use Function constructor as a safer alternative to eval
    return new Function('return ' + expression)();
  } catch (error) {
    throw new Error('Invalid mathematical expression');
  }
}
```

## Testing the Fixes

After implementing the fixes:

```bash
# From the chat directory
cd /Users/z/work/hanzo/chat

# Run TypeScript type checking
npm run type-check

# Run linting
npm run lint

# Run tests
npm test

# Build the project
npm run build
```

## CI/CD Considerations

1. Ensure all TypeScript errors are resolved before committing
2. Run `npm run type-check` as part of pre-commit hooks
3. Include type checking in CI pipeline
4. Consider using `strict` mode in tsconfig.json for better type safety

## Additional Resources

- [TypeScript Handbook - Type Assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)
- [MDN - Never use eval()!](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/eval#never_use_eval!)
- [Math.js Documentation](https://mathjs.org/docs/expressions/parsing.html)
- [Model Context Protocol (MCP) Specification](https://github.com/hanzoai/mcp)