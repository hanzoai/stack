# Hanzo Runtime Integration

This document describes the integration of the Hanzo Runtime service into the stack for code interpreter functionality.

## Overview

The Hanzo Runtime service provides secure, isolated code execution capabilities for the chat service. It enables AI-powered code interpretation with the following features:

- **Isolated Sandboxes**: Each code execution runs in a secure, isolated container
- **Language Support**: Python, JavaScript, and other language runtimes
- **Resource Limits**: CPU, memory, and execution time limits per sandbox
- **Persistent Storage**: Code and data persistence across executions
- **Docker-in-Docker**: Manages sandboxes using Docker containers

## Configuration

### Environment Variables

Key environment variables for the runtime service:

```bash
# Port Configuration
RUNTIME_PORT=8002  # API port (default: 8002)

# Database
DATABASE_URL=postgresql://hanzo:hanzo123@postgres:5432/runtime

# Storage (MinIO/S3)
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin
S3_ENDPOINT_URL=http://minio:9000
S3_BUCKET_NAME=runtime-sandboxes

# Security
JWT_SECRET=hanzo-runtime-secret
ENCRYPTION_KEY=hanzo-runtime-encryption

# Sandbox Limits
DEFAULT_SANDBOX_CPU_LIMIT=1
DEFAULT_SANDBOX_MEMORY_LIMIT=1024M
DEFAULT_SANDBOX_TIMEOUT=3600

# Chat Integration
CODE_INTERPRETER_ENABLED=true
```

### Docker Compose Services

The runtime service is configured in both `compose.yml` and `compose.dev.yml`:

1. **Production** (`compose.yml`):
   - Uses the production-optimized image
   - Runs on port 8002
   - Connects to PostgreSQL, Redis, and MinIO
   - Requires Docker socket access (privileged mode)

2. **Development** (`compose.dev.yml`):
   - Mounts source code for hot reload
   - Enables debug logging
   - Uses development build target
   - Runs with `pnpm nx serve api --watch`

### Volumes

- `runtime_data`: Persistent application data
- `runtime_sandboxes`: Sandbox file storage
- `runtime_logs`: Application logs (dev only)

## API Endpoints

The runtime service exposes the following key endpoints:

### Sandbox Management
- `POST /sandbox` - Create a new sandbox
- `GET /sandbox` - List sandboxes
- `GET /sandbox/:id` - Get sandbox details
- `DELETE /sandbox/:id` - Destroy sandbox

### Code Execution
- `POST /sandbox/:id/toolbox/process/execute` - Execute code synchronously
- `POST /sandbox/:id/toolbox/process/session` - Create execution session
- `POST /sandbox/:id/toolbox/process/session/:sessionId/exec` - Execute in session

### File Operations
- `POST /sandbox/:id/toolbox/file/write` - Write file
- `GET /sandbox/:id/toolbox/file/read` - Read file
- `GET /sandbox/:id/toolbox/file/list` - List files

## Integration with Chat Service

The chat service integrates with the runtime through:

1. **Environment Variables**:
   - `RUNTIME_API_URL=http://runtime:8000`
   - `CODE_INTERPRETER_ENABLED=true`

2. **Service Dependencies**:
   - Chat depends on runtime service being healthy
   - Network connectivity via `hanzo-network`

3. **Code Interpreter Features**:
   - Users can execute code blocks in chat
   - Results are displayed inline
   - Supports multiple programming languages
   - Maintains execution context across messages

## Security Considerations

1. **Isolation**: Each sandbox runs in an isolated Docker container
2. **Resource Limits**: CPU, memory, and time limits prevent abuse
3. **Network Restrictions**: Sandboxes have limited network access
4. **File System**: Sandboxes use temporary file systems
5. **Authentication**: JWT-based authentication required

## Troubleshooting

### Common Issues

1. **Runtime service not starting**:
   ```bash
   # Check logs
   docker logs hanzo-runtime
   
   # Verify Docker socket access
   ls -la /var/run/docker.sock
   ```

2. **Sandbox creation fails**:
   ```bash
   # Check Docker daemon
   docker info
   
   # Verify network exists
   docker network ls | grep hanzo-sandbox-network
   ```

3. **Code execution timeouts**:
   - Check `DEFAULT_SANDBOX_TIMEOUT` setting
   - Monitor resource usage with `docker stats`

### Health Checks

```bash
# Check runtime health
curl http://localhost:8002/health

# Check sandbox status
curl http://localhost:8002/sandbox
```

## Development

### Running Locally

```bash
# Start the stack with runtime
docker compose -f compose.yml -f compose.dev.yml up runtime

# Watch logs
docker logs -f hanzo-runtime

# Access the API
curl http://localhost:8002/health
```

### Testing Code Execution

```python
# Example: Create and use a sandbox
import requests

# Create sandbox
response = requests.post('http://localhost:8002/sandbox', json={
    'language': 'python',
    'name': 'test-sandbox'
})
sandbox = response.json()

# Execute code
response = requests.post(
    f'http://localhost:8002/sandbox/{sandbox["id"]}/toolbox/process/execute',
    json={
        'command': 'python -c "print(2 + 2)"'
    }
)
print(response.json())
```

## Future Enhancements

1. **GPU Support**: Enable GPU access for ML workloads
2. **Custom Images**: Support custom Docker images for sandboxes
3. **Collaborative Editing**: Real-time code collaboration
4. **Package Management**: Pre-installed common packages
5. **Output Streaming**: Stream long-running command outputs