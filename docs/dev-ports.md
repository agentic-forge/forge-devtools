# Agentic Forge - Development Port Scheme

## Overview

All services use a unified port scheme based on **4040** as the base port.

```
4040 = FORGE dev base (memorable, doesn't conflict with common ports)
```

## Port Allocation

### Core Services (4040-4049)

| Port | Service | Description |
|------|---------|-------------|
| 4040 | forge-ui | Vue.js chat interface |
| 4041 | forge-orchestrator | LLM agent loop (REST + SSE) |
| 4042 | forge-armory | MCP protocol gateway |
| 4043 | armory-admin-ui | Armory admin UI (Vite dev server) |
| 4044-4049 | *reserved* | Future core services |

### MCP Servers (4050+)

| Port | Service | Description |
|------|---------|-------------|
| 4050 | mcp-weather | Weather data (Open-Meteo API) |
| 4051 | mcp-web-search | Web search (Brave Search API) |
| 4052+ | *available* | Future MCP servers |

## Service Dependencies

```
                      forge-ui (:4040)
                           │
                           ▼
                 forge-orchestrator (:4041)
                           │
                           ▼
 armory-admin-ui ───► forge-armory (:4042)
    (:4043)                │
                    ┌──────┴──────┐
                    ▼             ▼
             mcp-weather    mcp-web-search
               (:4050)        (:4051)
```

**Startup order:** MCP servers → Armory → Admin UI / Orchestrator → UI

## Environment Variables

Each component has a `.env.example` file showing all available options.
The `.env` files are pre-configured for local development with the port scheme below.

### forge-orchestrator/.env

```bash
ORCHESTRATOR_HOST=0.0.0.0
ORCHESTRATOR_PORT=4041
ORCHESTRATOR_ARMORY_URL=http://localhost:4042/mcp

# Required: Set your OpenRouter API key
OPENROUTER_API_KEY=sk-or-...

# Optional
ORCHESTRATOR_DEFAULT_MODEL=anthropic/claude-sonnet-4
ORCHESTRATOR_SHOW_THINKING=true
ORCHESTRATOR_CONVERSATIONS_DIR=~/.forge/conversations
```

### forge-armory/.env

```bash
ARMORY_HOST=0.0.0.0
ARMORY_PORT=4042
ARMORY_DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/forge_armory
```

### forge-ui/.env

```bash
VITE_API_URL=http://localhost:4041
```

### MCP Servers

MCP servers use command-line arguments (no .env files needed):

```bash
# mcp-weather
uv run python -m forge_mcp_weather.server --port 4050

# mcp-web-search (requires BRAVE_API_KEY)
BRAVE_API_KEY=... uv run python -m forge_mcp_web_search.server --port 4051
```

## Adding New MCP Servers

1. Assign the next available port (4052, 4053, etc.)
2. Update this document
3. Add the server to `dev-start.sh`
4. Register the backend in Armory:
   ```bash
   cd forge-armory
   uv run armory backend add <name> --url http://localhost:<port>/mcp
   ```
