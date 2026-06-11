# Hanzo Memory Service

## Add memory to any AI application!

A high-performance FastAPI service that provides memory and knowledge management capabilities for AI applications. Built with LanceDB vector database (works on all platforms including browsers via WASM), local embeddings, and LLM for flexible LLM integration.

## Features

- **🧠 Intelligent Memory Management**: Store and retrieve contextual memories with semantic search
- **📚 Knowledge Base System**: Organize facts in hierarchical knowledge bases with parent-child relationships
- **💬 Chat History**: Store and search conversation history with de-duplication
- **🔍 Unified Search API**: Fast semantic search using FastEmbed embeddings
- **🤖 Flexible LLM Support**: Use any LLM via LLM (OpenAI, Anthropic, Ollama, etc.)
- **🔐 Multi-tenancy**: Secure user and project-based data isolation
- **🚀 High Performance**: Local embeddings and efficient vector storage
- **🗄️ Cross-Platform Database**: LanceDB works everywhere - Linux, macOS, Windows, and even browsers
- **🔌 MCP Support**: Model Context Protocol server for AI tool integration
- **📦 Easy Deployment**: Docker support and uvx compatibility

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   FastAPI       │────▶│  Vector DB      │────▶│   Embeddings    │
│   Server        │     │ (LanceDB/       │     │ (FastEmbed/     │
└─────────────────┘     │  InfinityDB)    │     │  LanceDB)       │
         │              └─────────────────┘     └─────────────────┘
         ▼                                                │
┌─────────────────┐                              ┌─────────────────┐
│   LLM       │                              │   Local Models  │
│   (LLM Bridge)  │                              │   (BGE, etc.)   │
└─────────────────┘                              └─────────────────┘
```

## Quick Start

### Install with uvx

```bash
# Install and run directly with uvx
uvx hanzo-memory

# Or install globally
uvx install hanzo-memory
```

### Install from source

```bash
# Clone the repository
git clone https://github.com/hanzoai/memory
cd memory

# Install with uv
make setup

# Run the server
make dev
```

### Docker

```bash
# Using docker-compose
docker-compose up

# Or build and run manually
docker build -t hanzo-memory .
docker run -p 4000:4000 -v $(pwd)/data:/app/data hanzo-memory
```

## Configuration

Create a `.env` file (see `.env.example`):

```env
# API Authentication
HANZO_API_KEY=your-api-key-here
HANZO_DISABLE_AUTH=false  # Set to true for local development

# LLM Configuration (choose one)
# OpenAI
HANZO_LLM_MODEL=gpt-4o-mini
OPENAI_API_KEY=your-openai-key

# Anthropic
HANZO_LLM_MODEL=claude-3-haiku-20240307
ANTHROPIC_API_KEY=your-anthropic-key

# Local Models (Ollama)
HANZO_LLM_MODEL=ollama/llama3.2
HANZO_LLM_API_BASE=http://localhost:11434

# Embedding Model
HANZO_EMBEDDING_MODEL=BAAI/bge-small-en-v1.5

# Database Backend (optional, defaults to lancedb)
HANZO_DB_BACKEND=lancedb
HANZO_LANCEDB_PATH=data/lancedb
```

## Database Backends

Hanzo Memory supports multiple vector database backends:

### LanceDB (Default)
- Modern embedded vector database that works on ALL platforms
- Cross-platform: Linux, macOS, Windows, ARM, and even browsers (via WASM)
- Built-in support for FastEmbed and sentence-transformers
- Efficient columnar storage format (Apache Arrow/Parquet)
- Native vector similarity search
- Can be embedded in Python, JavaScript/TypeScript, Rust applications

### InfinityDB (Alternative, Linux/Windows only)
- High-performance embedded vector database
- Not available on macOS
- Optimized for production workloads
- Built-in vector indexing

To configure the database backend:

```env
# Use LanceDB
HANZO_DB_BACKEND=lancedb
HANZO_LANCEDB_PATH=data/lancedb

# Use InfinityDB
HANZO_DB_BACKEND=infinity
HANZO_INFINITY_DB_PATH=data/infinity_db
```

## API Documentation

For complete API documentation including all endpoints, request/response formats, and examples, see [docs/API.md](docs/API.md).

### Quick API Overview

- **Memory Management**: `/v1/remember`, `/v1/memories/*`
- **Knowledge Bases**: `/v1/kb/*`, `/v1/kb/facts/*`
- **Chat Sessions**: `/v1/chat/sessions/*`, `/v1/chat/messages/*`
- **Search**: Unified semantic search across all data types
- **MCP Server**: Model Context Protocol integration for AI tools

### LLM Features

The service can:
- **Summarize content** for knowledge extraction
- **Generate knowledge update instructions** in JSON format
- **Filter search results** for relevance
- **Strip PII** from stored content

Example summarization request:
```python
llm_service.summarize_for_knowledge(
    content="Long document...",
    skip_summarization=False,  # Set to True to skip
    provided_summary="Optional pre-made summary"
)
```

Returns:
```json
{
  "summary": "Concise summary of content",
  "knowledge_instructions": {
    "action": "add_fact",
    "facts": [{"content": "Extracted fact", "metadata": {...}}],
    "reasoning": "Why these facts are important"
  }
}
```

## Development

### Running Tests

```bash
# Run all tests
make test

# Run with coverage
make test-cov

# Run specific test
uvx pytest tests/test_memory_api.py -v
```

### Code Quality

```bash
# Format code
make format

# Run linter
make lint

# Type checking
make type-check
```

### Project Structure

```
memory/
├── src/hanzo_memory/
│   ├── api/          # API authentication
│   ├── db/           # InfinityDB client
│   ├── models/       # Pydantic models
│   ├── services/     # Business logic
│   ├── config.py     # Settings
│   └── server.py     # FastAPI app
├── tests/            # Pytest tests
├── Makefile          # Build automation
└── pyproject.toml    # Project config
```

## Deployment

### Production Checklist

1. Set strong `HANZO_API_KEY`
2. Configure appropriate LLM model and API keys
3. Set `HANZO_DISABLE_AUTH=false`
4. Configure data persistence volume
5. Set up monitoring and logging
6. Configure rate limiting if needed

### Scaling Considerations

- InfinityDB embedded runs in-process (no separate DB server)
- FastEmbed generates embeddings locally (no API calls)
- LLM calls can be directed to local models for full offline operation
- Use Redis for caching in high-traffic scenarios

## Contributing

Pull requests are welcome! Please:
1. Write tests for new features
2. Follow existing code style
3. Update documentation as needed
4. Run `make check` before submitting

## License

BSD License - see LICENSE file for details.
