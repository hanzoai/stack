# Hanzo Dev - AI Coding OS

**Chat-first REPL with Multi-Orchestrator Support**

Version 0.3.20 brings revolutionary features to Hanzo Dev, transforming it into a complete AI Coding OS with intelligent fallback, memory persistence, and seamless orchestration.

## 🚀 Quick Start

```bash
# Install
pip install hanzo>=0.3.20

# Run with automatic AI selection
hanzo dev

# Run with specific orchestrator
hanzo dev --orchestrator gpt-4
hanzo dev --orchestrator claude
hanzo dev --orchestrator local:llama3.2
```

## ✨ Key Features

### 1. **Chat-First Interface**
Just type naturally! No commands needed.
```
> Write a REST API in FastAPI
> Help me debug this error
> Refactor this function for better performance
```

### 2. **Intelligent Fallback**
Automatically tries all available AI options:
- ✅ OpenAI API (GPT-4/GPT-5)
- ✅ Anthropic API (Claude 3.5)
- ✅ Google API (Gemini Pro)
- ✅ OpenAI CLI (no API key needed)
- ✅ Claude Desktop
- ✅ Ollama (local models)
- ✅ Free APIs (Codestral, StarCoder)

### 3. **Memory Management**
Persistent context like Claude Desktop:
```
#memory show         - View current memories
#memory add <text>   - Add important context
#memory clear        - Clear memories
#memory export       - Save memories to file
#memory context      - Show AI context
```

### 4. **Multi-Orchestrator Support**

| Orchestrator | Description | Requirements |
|-------------|-------------|--------------|
| `gpt-5` | Ultimate code AI | OPENAI_API_KEY |
| `gpt-4` | Production OpenAI | OPENAI_API_KEY |
| `claude` | Claude 3.5 Sonnet | ANTHROPIC_API_KEY |
| `codex` | OpenAI CLI | OpenAI CLI installed |
| `local:llama3.2` | Local Llama | Ollama installed |
| `auto` | Automatic selection | Tries all available |

### 5. **System 2 Thinking**
Deep analysis with critic agents:
- Code review and improvement suggestions
- Bug detection and security analysis
- Performance optimization recommendations
- Best practices enforcement

### 6. **Cost Optimization**
90% cost reduction through intelligent routing:
- Simple tasks → Local models ($0.00)
- Complex tasks → Premium APIs ($0.03-$0.05)
- Code review → Specialized models
- Documentation → Free APIs

## 📋 Commands

### Chat Commands (/)
```
/help      - Show available commands
/status    - System status
/clear     - Clear screen
/exit      - Exit REPL
```

### Memory Commands (#)
```
#memory [show]        - Display memories
#memory add <text>    - Add memory
#memory remove <id>   - Remove memory
#memory clear         - Clear all memories
#memory save          - Save to disk
#memory export [file] - Export memories
#memory import <file> - Import memories
#memory context       - Show AI context
#memory help          - Memory help
```

## 🔧 Configuration

### Environment Variables
```bash
# API Keys (optional - will use fallbacks)
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GOOGLE_API_KEY="..."

# Preferences
export HANZO_DEV_MODEL="gpt-4"  # Default model
export HANZO_DEV_MEMORY="/path/to/memories"  # Memory location
```

### Memory Persistence
Memories are automatically saved to:
- Project: `<workspace>/.hanzo/memory/`
- Global: `~/.hanzo/memory/`

### Fallback Priority
1. API keys (fastest, most reliable)
2. CLI tools (no API key needed)
3. Local models (free, requires setup)
4. Free cloud APIs (rate limited)

## 🎯 Use Cases

### 1. Code Development
```
> Create a Python web scraper with error handling
> Add type hints to this function
> Write unit tests for the API endpoints
```

### 2. Debugging
```
> Help me fix this TypeError
> Why is my async function not awaiting properly?
> Analyze this stack trace
```

### 3. Code Review
```
> Review this PR for security issues
> Suggest performance improvements
> Check for code smells and anti-patterns
```

### 4. Learning
```
> Explain how decorators work in Python
> What's the difference between async and threading?
> Show me best practices for error handling
```

## 🛠️ Installation Options

### Basic Install
```bash
pip install hanzo
```

### With All Features
```bash
pip install "hanzo[all]"
```

### For Development
```bash
pip install "hanzo[dev]"
```

### Local Models (Ollama)
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull models
ollama pull llama3.2
ollama pull codellama
ollama pull mistral
```

### CLI Tools
```bash
# OpenAI CLI
pip install openai-cli

# Claude Desktop
# Download from https://claude.ai/download

# Gemini CLI
pip install google-generativeai
```

## 🔍 Troubleshooting

### No AI Response
1. Check available options: `hanzo dev` will auto-detect
2. Set API keys: `export OPENAI_API_KEY="..."`
3. Install tools: `pip install openai-cli`
4. Use local: `ollama pull llama3.2`

### Memory Issues
1. Clear memories: `#memory clear`
2. Export/import: `#memory export backup.json`
3. Check location: `~/.hanzo/memory/`

### Performance
1. Use local models for simple tasks
2. Enable caching: Memory persistence helps
3. Batch operations when possible

## 📊 Feature Comparison

| Feature | Hanzo Dev | Cursor | GitHub Copilot | Claude Desktop |
|---------|-----------|--------|----------------|----------------|
| Chat Interface | ✅ | ✅ | ❌ | ✅ |
| Multi-Model | ✅ | ❌ | ❌ | ❌ |
| Memory Persist | ✅ | ❌ | ❌ | ✅ |
| Local Models | ✅ | ❌ | ❌ | ❌ |
| Free Options | ✅ | ❌ | ❌ | ❌ |
| Fallback | ✅ | ❌ | ❌ | ❌ |
| MCP Tools | ✅ | ❌ | ❌ | ✅ |
| Cost Optimize | ✅ | ❌ | ❌ | ❌ |

## 🚀 What's New in 0.3.20

- **Intelligent Fallback**: Automatically tries all available AI options
- **Memory Management**: Persistent context with #memory commands
- **Smart Routing**: 90% cost reduction through intelligent model selection
- **Enhanced UX**: Claude Desktop-style UI with better formatting
- **Session Tracking**: Preserves context across sessions
- **Export/Import**: Save and share memory configurations

## 📚 Examples

### Basic Chat
```python
$ hanzo dev
╭─────────────────────────────────────────╮
│ Hanzo Dev - AI Coding OS                │
│ Chat-first interface with memory        │
╰─────────────────────────────────────────╯

› Write a fibonacci function in Python

AI Response:
def fibonacci(n: int) -> int:
    """Calculate nth Fibonacci number."""
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

### With Memory
```python
› #memory add Always use type hints in Python
Added memory: a3f2d8c1

› Write a function to calculate factorial

AI Response:
def factorial(n: int) -> int:
    """Calculate factorial of n."""
    if n <= 1:
        return 1
    return n * factorial(n - 1)
```

### Cost-Optimized
```python
› Fix this typo: prin("hello")

[Using local model - $0.00]
AI Response:
print("hello")

› Implement a distributed cache system

[Using GPT-4 - $0.03]
AI Response:
[Complex implementation with Redis, consistent hashing, etc.]
```

## 🤝 Contributing

We welcome contributions! Areas of focus:
- Additional orchestrator integrations
- Memory management improvements
- Cost optimization strategies
- UI/UX enhancements

## 📄 License

Apache 2.0 - See LICENSE file

## 🔗 Links

- [Documentation](https://docs.hanzo.ai)
- [GitHub](https://github.com/hanzoai/python-sdk)
- [PyPI](https://pypi.org/project/hanzo/)
- [Discord](https://discord.gg/CJCyAsm9Vr)

---

**Built with ❤️ by Hanzo AI**

*Making AI accessible, affordable, and powerful for every developer.*