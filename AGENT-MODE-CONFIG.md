# Hanzo Chat Agent Mode Configuration

## Changes Made

1. **Disabled Brand Mode**
   - Set `BRAND_MODE: "false"` to show all features
   - Brand mode is now opt-in, not default
   - This enables the full Chat UI with all provider options

2. **Enabled Agent Features**
   - Added `SHOW_AGENT_MODE: "true"`
   - Added `AGENTS_ENABLED: "true"`
   - Disabled assistants with `ASSISTANTS_ENABLED: "false"`

3. **Multi-Provider Support**
   - Configured endpoints for multiple AI providers:
     - **Hanzo Router** - Unified gateway at http://router:4000
     - **OpenAI** - Direct access with OPENAI_API_KEY
     - **Anthropic** - Direct access with ANTHROPIC_API_KEY
     - **Google/Gemini** - Direct access with GEMINI_API_KEY
     - **Groq** - Direct access with GROQ_API_KEY
   
4. **Auto-Detection of API Keys**
   - All API keys are automatically pulled from environment variables
   - If not set, defaults to "user_provided" allowing users to enter their own

## Available Models

### Via Hanzo Router
- GPT-4o, GPT-4o-mini, GPT-4, GPT-3.5-turbo
- Claude 3.5 Sonnet, Claude 3 Opus, Claude 3 Haiku

### Direct OpenAI
- GPT-4o, GPT-4o-mini, GPT-4-turbo, GPT-4, GPT-3.5-turbo

### Direct Anthropic  
- Claude 3.5 Sonnet (latest)
- Claude 3.5 Haiku (latest)
- Claude 3 Opus, Sonnet, Haiku

### Direct Google
- Gemini Pro
- Gemini Pro Vision

### Direct Groq
- Llama 3.2 90B, 70B
- Llama 3.1 70B
- Mixtral 8x7B

## Usage

Users can now:
1. Select from multiple AI providers
2. Use agents for specialized tasks
3. Switch between models easily
4. Use their own API keys if environment keys aren't set
5. Access the Hanzo Router for unified API access

## For Branded Deployments

To create a branded deployment, set:
```yaml
BRAND_MODE: "true"
BRAND_NAME: "Your Brand"
# ... other brand settings
```

This will hide provider selection and show only your configured models.