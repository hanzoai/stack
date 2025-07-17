#!/bin/bash

echo "🧪 Running Hanzo Stack Integration Tests"
echo "======================================="
echo ""

# Run tests with better output
npm test -- --run --reporter=verbose

# Get exit code
TEST_EXIT_CODE=$?

echo ""
echo "📊 Test Summary"
echo "=============="

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ All tests passed!"
else
  echo "❌ Some tests failed. See output above."
fi

echo ""
echo "🐳 Current Docker Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep hanzo

exit $TEST_EXIT_CODE