# API Keys Guide

This guide explains how to obtain the API keys needed for Agentic Forge.

## LLM Provider Keys (Required - choose ONE)

You need at least one LLM provider API key. We recommend **OpenRouter** as it gives you access to models from multiple providers with a single key.

### OpenRouter (Recommended)

OpenRouter provides unified access to Claude, GPT-4, Gemini, Llama, Mistral, and many more models.

1. Go to [openrouter.ai](https://openrouter.ai/)
2. Sign up or log in
3. Navigate to [Keys](https://openrouter.ai/keys)
4. Click "Create Key"
5. Copy the key (starts with `sk-or-`)

```bash
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxx
```

**Pricing:** Pay per token, varies by model. Most models have free tiers for testing.

**Default model:** `anthropic/claude-sonnet-4`

### OpenAI

Direct access to GPT-4, GPT-4o, and other OpenAI models.

1. Go to [platform.openai.com](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to [API Keys](https://platform.openai.com/api-keys)
4. Click "Create new secret key"
5. Copy the key (starts with `sk-`)

```bash
OPENAI_API_KEY=sk-xxxxxxxxxxxx
```

**Pricing:** Pay per token. See [OpenAI Pricing](https://openai.com/pricing).

### Anthropic

Direct access to Claude models.

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to [API Keys](https://console.anthropic.com/settings/keys)
4. Click "Create Key"
5. Copy the key (starts with `sk-ant-`)

```bash
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxx
```

**Pricing:** Pay per token. See [Anthropic Pricing](https://www.anthropic.com/pricing).

### Google (Gemini)

Access to Gemini models.

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Get API key" or navigate to [API Keys](https://aistudio.google.com/app/apikey)
4. Create a new key
5. Copy the key

```bash
GEMINI_API_KEY=xxxxxxxxxxxx
```

**Pricing:** Free tier available. See [Gemini Pricing](https://ai.google.dev/pricing).

---

## Web Search API Key (Optional)

The web search MCP server uses Brave Search API. Without this key, web search functionality will be disabled, but everything else works.

### Brave Search API

1. Go to [brave.com/search/api](https://brave.com/search/api/)
2. Click "Get Started for Free"
3. Sign up or log in
4. Create a new app
5. Copy the API key

```bash
BRAVE_API_KEY=xxxxxxxxxxxx
```

**Pricing:**
- **Free tier:** 2,000 queries/month, 1 query/second
- **Paid plans:** Starting at $5/month for more queries

---

## Setting Up Your Environment

### For Docker Compose

Edit the `.env` file in the `forge-devtools` directory:

```bash
cd forge-devtools
cp .env.example .env

# Edit .env with your preferred editor
nano .env  # or vim, code, etc.
```

Add your keys:
```bash
# Choose ONE LLM provider
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxx

# Optional but recommended
BRAVE_API_KEY=xxxxxxxxxxxx
```

### For Native Development

Each service has its own `.env` file. The key environment variables are:

**forge-orchestrator/.env:**
```bash
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxx
# Or use OPENAI_API_KEY, ANTHROPIC_API_KEY, or GEMINI_API_KEY
```

**mcp-web-search:**
```bash
# Pass as environment variable when running
BRAVE_API_KEY=xxxxxxxxxxxx uv run python -m forge_mcp_web_search.server
```

---

## Model Selection

When using OpenRouter, you can change the default model:

```bash
# In .env
ORCHESTRATOR_DEFAULT_MODEL=anthropic/claude-sonnet-4  # Default
# ORCHESTRATOR_DEFAULT_MODEL=openai/gpt-4o
# ORCHESTRATOR_DEFAULT_MODEL=google/gemini-2.0-flash-exp
# ORCHESTRATOR_DEFAULT_MODEL=meta-llama/llama-3.3-70b-instruct
```

See [OpenRouter Models](https://openrouter.ai/models) for all available models.

---

## Security Notes

- **Never commit API keys** to version control
- The `.env` file is gitignored by default
- Rotate keys if you suspect they've been exposed
- Use environment variables in CI/CD instead of files
