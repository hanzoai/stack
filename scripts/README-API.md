# Starting the Hanzo API Service

This directory contains multiple scripts to start the real Hanzo API service (LLM Gateway). Choose the method that works best for your setup.

## Available Scripts

### 1. `start-hanzo-api.sh` (Recommended for Development)
Starts the API service directly from the source code in `/Users/z/work/hanzo/llm`.

```bash
./start-hanzo-api.sh
```

**Features:**
- Automatically creates and activates Python virtual environment
- Installs dependencies if needed
- Configurable host/port via environment variables
- Uses the full proxy CLI with all options

**Configuration:**
```bash
# Custom port and host
PORT=8000 HOST=127.0.0.1 ./start-hanzo-api.sh

# With custom config file
CONFIG_FILE=/path/to/config.yaml ./start-hanzo-api.sh
```

### 2. `start-hanzo-api-simple.sh` (Quick Start)
A simplified version that uses the `run_server.py` wrapper.

```bash
./start-hanzo-api-simple.sh

# With config file
./start-hanzo-api-simple.sh --config /path/to/config.yaml
```

### 3. `start-hanzo-api-docker.sh` (Production-like)
Runs the official Hanzo API Docker image.

```bash
./start-hanzo-api-docker.sh
```

**Features:**
- Uses official Docker image
- Automatic container management
- Production-ready setup
- No local Python environment needed

## Environment Variables

All scripts support these environment variables:

```bash
# Database connections
export DATABASE_URL="postgresql://user:pass@localhost:5432/hanzo"
export REDIS_URL="redis://localhost:6379"

# API Keys (at least one required)
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export TOGETHER_API_KEY="..."

# Server configuration
export PORT=4000
export HOST=0.0.0.0
export LLM_MODE=PRODUCTION  # or DEV

# Docker specific
export HANZO_API_IMAGE="ghcr.io/hanzoai/api:latest"
```

## API Endpoints

Once started, the API provides:

- **Base URL**: `http://localhost:4000`
- **Health Check**: `http://localhost:4000/health`
- **OpenAPI Docs**: `http://localhost:4000/docs`
- **Metrics**: `http://localhost:4000/metrics`

## Example API Usage

```bash
# Test the API
curl http://localhost:4000/health

# Make a chat completion request
curl http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Troubleshooting

### Port Already in Use
```bash
# Find process using port 4000
lsof -i :4000

# Kill the process
kill -9 <PID>
```

### Missing Dependencies
```bash
# For source installation
cd /Users/z/work/hanzo/llm
python -m venv .venv
source .venv/bin/activate
pip install -e ".[proxy]"
```

### Docker Issues
```bash
# Check Docker daemon
docker info

# View container logs
docker logs hanzo-api

# Remove old container
docker rm -f hanzo-api
```

### No API Keys
The API requires at least one LLM provider API key. Set one of:
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `TOGETHER_API_KEY`

## Advanced Configuration

### Using a Config File

Create a `config.yaml`:
```yaml
model_list:
  - model_name: gpt-3.5-turbo
    litellm_params:
      model: gpt-3.5-turbo
      api_key: ${OPENAI_API_KEY}
  
  - model_name: claude-3
    litellm_params:
      model: claude-3-sonnet-20240229
      api_key: ${ANTHROPIC_API_KEY}

general_settings:
  master_key: "sk-hanzo-xxx"  # Your master API key
  database_url: ${DATABASE_URL}
  
router_settings:
  routing_strategy: "simple-shuffle"
  redis_url: ${REDIS_URL}
```

Then run:
```bash
CONFIG_FILE=config.yaml ./start-hanzo-api.sh
```

## Integration with Hanzo Stack

The API service integrates with:
- **PostgreSQL**: For storing API keys, usage data, and models
- **Redis**: For caching and rate limiting
- **MinIO**: For file storage (optional)
- **Chat UI**: As the LLM backend

Make sure these services are running before starting the API.