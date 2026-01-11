# Agentic Forge - Developer Tools

Development environment setup and tools for [Agentic Forge](https://agentic-forge.github.io) - an experimentation platform for building efficient AI agents.

## Quick Start

### Option 1: Docker Compose (Recommended)

The fastest way to get all services running:

```bash
# Clone all repositories
./scripts/clone-repos.sh

# Copy environment template
cp .env.example .env

# Add your API keys to .env (at minimum, one LLM provider key)
# See docs/API_KEYS.md for details

# Start all services
docker compose up
```

Open http://localhost:4040 in your browser.

### Option 2: Native Development (tmux)

For active development with hot reload:

```bash
# Prerequisites: tmux, uv, bun, PostgreSQL

# Clone all repositories
./scripts/clone-repos.sh

# Start all services in tmux panes
./scripts/dev-start.sh

# Stop services
./scripts/dev-stop.sh
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| [forge-ui](https://github.com/agentic-forge/forge-ui) | 4040 | Vue.js chat interface |
| [forge-orchestrator](https://github.com/agentic-forge/forge-orchestrator) | 4041 | LLM agent loop |
| [forge-armory](https://github.com/agentic-forge/forge-armory) | 4042 | MCP protocol gateway |
| armory-admin-ui | 4043 | Armory admin interface |
| [mcp-weather](https://github.com/agentic-forge/mcp-weather) | 4050 | Weather MCP server |
| [mcp-web-search](https://github.com/agentic-forge/mcp-web-search) | 4051 | Web search MCP server |

## Documentation

- [Getting Started Guide](docs/GETTING_STARTED.md) - Full setup instructions
- [API Keys Guide](docs/API_KEYS.md) - How to obtain required API keys
- [Port Allocation](docs/dev-ports.md) - Service ports and architecture

## Required API Keys

You need **at least one** LLM provider API key:

| Provider | Get Key | Notes |
|----------|---------|-------|
| OpenRouter | [openrouter.ai/keys](https://openrouter.ai/keys) | **Recommended** - Access to many models |
| OpenAI | [platform.openai.com](https://platform.openai.com/api-keys) | GPT-4, GPT-4o |
| Anthropic | [console.anthropic.com](https://console.anthropic.com/settings/keys) | Claude models |
| Google | [aistudio.google.com](https://aistudio.google.com/app/apikey) | Gemini models |

**Optional but recommended:**
- [Brave Search API](https://brave.com/search/api/) - For web search functionality (free tier: 2,000 queries/month)

## Repository Structure

```
forge-devtools/
├── docker-compose.yml     # All services orchestrated
├── .env.example           # Environment template
├── docker/
│   ├── Dockerfile.python  # Python services (uv)
│   └── Dockerfile.node    # Node services (bun)
├── scripts/
│   ├── clone-repos.sh     # Clone all Forge repos
│   ├── dev-start.sh       # tmux-based development
│   ├── dev-stop.sh        # Stop tmux session
│   └── dev-status.sh      # Check service status
└── docs/
    ├── GETTING_STARTED.md # Full setup guide
    ├── API_KEYS.md        # API key instructions
    └── dev-ports.md       # Port allocation
```

## Links

- **Landing Page:** https://agentic-forge.github.io
- **Organization:** https://github.com/agentic-forge
- **Project Board:** https://github.com/orgs/agentic-forge/projects/1
