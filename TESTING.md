# Hanzo Stack Testing Guide

## Overview

The Hanzo Stack includes a comprehensive testing framework that allows you to test all 50+ services locally with proper isolation and mocking of external dependencies.

## Test Environment

The test environment is configured via `.env.test` which:
- Uses separate test databases (hanzo_test)
- Mocks all external APIs (OpenAI, Anthropic, Stripe, etc.)
- Configures test-specific settings
- Isolates from development/production data

## Running Tests

### Quick Start
```bash
# Run all tests with one command
make test

# Or use the test script directly
./test.sh all
```

### Interactive Testing
```bash
# Launch interactive test menu
./run-local-test.sh
```

### Specific Test Types
```bash
make test-unit          # Unit tests only
make test-integration   # Integration tests
make test-load         # Load/performance tests
make test-security     # Security scans
make test-quick        # Quick smoke test
```

## Test Architecture

### Environment Isolation
- **Test Databases**: Separate PostgreSQL, MongoDB, ClickHouse databases
- **Test Namespaces**: Redis namespaces, MinIO buckets
- **Mock Services**: External APIs replaced with mocks
- **Network Isolation**: Dedicated Docker network

### Mock Services
Only external (non-Hanzo) services are mocked:
- OpenAI API → MockServer with predefined responses
- Anthropic API → MockServer with Claude responses
- Stripe → Official stripe-mock
- OAuth Providers → Custom OAuth mock
- SMTP → MailHog for email testing

All Hanzo services run real instances:
- LLM Gateway (routes to mocks)
- Chat (with MCP tools)
- API (full functionality)
- Cloud (Langfuse)
- Search (with Meilisearch)
- IAM (Casdoor)

## Test Structure

```
tests/
├── integration/          # Cross-service tests
│   ├── test_full_stack.py
│   ├── test_llm_gateway.py
│   ├── test_api.py
│   └── test_*.py
├── unit/                # Service unit tests
├── k6/                  # Load test scripts
└── fixtures/            # Test data
```

## Writing Tests

### Integration Test Example
```python
def test_cross_service_workflow(self):
    """Test workflow across multiple services"""
    # 1. Create project via API
    project = create_test_project()
    
    # 2. Start chat conversation
    conversation = start_chat(project.id)
    
    # 3. Send message (creates trace)
    message = send_message(conversation.id, "Hello")
    
    # 4. Verify in Cloud/Langfuse
    trace = get_trace_from_cloud(message.trace_id)
    assert trace.project_id == project.id
```

### Service-Specific Test
```python
class TestLLMGateway:
    def test_multi_provider_routing(self):
        """Test routing to different providers"""
        # Test OpenAI format
        response = llm_gateway.chat_completion(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": "Hello"}]
        )
        assert response.provider == "openai"
        
        # Test Anthropic format
        response = llm_gateway.messages(
            model="claude-3-sonnet",
            messages=[{"role": "user", "content": "Hello"}]
        )
        assert response.provider == "anthropic"
```

## Environment Variables

Key test environment variables:
```bash
# Test mode flags
TEST_MODE=true
MOCK_EXTERNAL_APIS=true

# Test databases
POSTGRES_DB=hanzo_test
MONGODB_DATABASE=hanzo_test

# Mock endpoints
OPENAI_BASE_URL=http://mock-openai:1080/v1
ANTHROPIC_BASE_URL=http://mock-anthropic:1080/v1

# Test data
SEED_TEST_DATA=true
TEST_USER_COUNT=10
TEST_PROJECT_COUNT=5
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run tests
  run: |
    cp .env.test .env
    ./test.sh all
```

### Local CI
```bash
# Run same tests as CI locally
docker compose -f docker-compose.yml \
  -f docker-compose.test.yml \
  -f docker-compose.mocks.yml \
  --env-file .env.test \
  run integration-tests
```

## Debugging Tests

### View logs
```bash
# All services
docker compose --env-file .env.test logs

# Specific service
docker compose --env-file .env.test logs llm-gateway

# Follow logs
docker compose --env-file .env.test logs -f
```

### Access containers
```bash
# Shell into test runner
docker compose --env-file .env.test \
  exec integration-tests /bin/bash

# Shell into service
docker compose --env-file .env.test \
  exec api /bin/bash
```

### Test database access
```bash
# PostgreSQL
docker compose --env-file .env.test \
  exec postgres psql -U hanzo_test -d hanzo_test

# MongoDB
docker compose --env-file .env.test \
  exec mongodb mongosh hanzo_test
```

## Performance Testing

### Load test with k6
```bash
# Run load test
make test-load

# Custom k6 script
docker compose -f docker-compose.test.yml run k6 \
  run /scripts/custom-load-test.js
```

### Metrics
- Response times (p95, p99)
- Requests per second
- Error rates
- Resource usage

## Security Testing

### OWASP ZAP scan
```bash
make test-security
```

### Manual security test
```bash
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:8000 -r security-report.html
```

## Best Practices

1. **Isolation**: Always use `.env.test` for testing
2. **Cleanup**: Tests should clean up after themselves
3. **Idempotency**: Tests should be runnable multiple times
4. **Mocking**: Only mock external services, not Hanzo services
5. **Parallel**: Use pytest-xdist for parallel execution
6. **Fixtures**: Use shared fixtures for common setup

## Troubleshooting

### Tests failing locally but not in CI
- Check Docker memory allocation (need 16GB+)
- Ensure clean environment: `make clean`
- Verify mock services are running

### Timeout errors
- Increase timeouts in `.env.test`
- Check service health: `make health`
- Review service logs

### Database connection errors
- Ensure databases are initialized: `./test.sh all`
- Check credentials in `.env.test`
- Verify network connectivity

## Adding New Tests

1. Create test file in appropriate directory
2. Use existing fixtures and helpers
3. Follow naming convention: `test_*.py`
4. Add to CI workflow if needed
5. Document any special requirements

## Test Coverage

Current coverage:
- Unit tests: Core business logic
- Integration tests: Service interactions
- Load tests: Performance benchmarks
- Security tests: OWASP compliance
- E2E tests: User workflows