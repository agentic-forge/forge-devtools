# Getting Started with Agentic Forge

This guide will help you set up and run Agentic Forge on your local machine.

## Prerequisites

### For Docker Compose setup (recommended)
- [Docker](https://docs.docker.com/get-docker/) with Docker Compose v2
- Git

### For native development
- [uv](https://docs.astral.sh/uv/getting-started/installation/) - Python package manager
- [Bun](https://bun.sh/) - JavaScript runtime
- [tmux](https://github.com/tmux/tmux/wiki) - Terminal multiplexer
- [PostgreSQL](https://www.postgresql.org/) 15+
- Git

## Step 1: Clone the Repositories

All Agentic Forge components live in separate repositories. Clone them all:

```bash
# Create a workspace directory
mkdir -p ~/projects/agentic-forge && cd ~/projects/agentic-forge

# Clone devtools first
git clone https://github.com/agentic-forge/forge-devtools.git
cd forge-devtools

# Run the clone script to get all repos
./scripts/clone-repos.sh
```

Or clone them manually:

```bash
cd ~/projects/agentic-forge
git clone https://github.com/agentic-forge/forge-ui.git
git clone https://github.com/agentic-forge/forge-orchestrator.git
git clone https://github.com/agentic-forge/forge-armory.git
git clone https://github.com/agentic-forge/mcp-weather.git mcp-servers/mcp-weather
git clone https://github.com/agentic-forge/mcp-web-search.git mcp-servers/mcp-web-search
```

## Step 2: Configure Environment

```bash
cd forge-devtools

# Copy the environment template
cp .env.example .env

# Edit .env and add your API keys
# At minimum, you need ONE LLM provider key
```

### Required: LLM Provider Key

You need at least one of these (see [API_KEYS.md](API_KEYS.md) for details):

| Provider | Environment Variable | Recommended For |
|----------|---------------------|-----------------|
| OpenRouter | `OPENROUTER_API_KEY` | Best choice - access to many models |
| OpenAI | `OPENAI_API_KEY` | If you only need GPT models |
| Anthropic | `ANTHROPIC_API_KEY` | If you only need Claude |
| Google | `GEMINI_API_KEY` | If you only need Gemini |

### Optional: Web Search

For web search functionality, add a Brave Search API key:
```bash
BRAVE_API_KEY=your-key-here
```

## Step 3: Start the Services

### Option A: Docker Compose (Recommended)

```bash
cd forge-devtools

# Start all services
docker compose up

# Or run in background
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Option B: Native Development with tmux

This option gives you hot reload for active development:

```bash
# First, set up the database
createdb forge_armory  # or use Docker: docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:16

# Copy .env files to each service (one-time setup)
# forge-orchestrator/.env
# forge-armory/.env
# etc.

# Start all services
cd forge-devtools
./scripts/dev-start.sh

# This opens a tmux session with all services in separate panes
# Use Ctrl+b then a number to switch panes
# Use Ctrl+b d to detach (services keep running)

# Stop services
./scripts/dev-stop.sh
```

## Step 4: Verify Setup

1. **Chat UI:** Open http://localhost:4040
   - You should see the Forge chat interface

2. **Armory Admin:** Open http://localhost:4043
   - Check that MCP backends are registered
   - You should see `weather` and `web-search` backends

3. **Test a conversation:**
   - In the chat UI, try: "What's the weather in London?"
   - The orchestrator should use the weather MCP server

## Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Chat UI | http://localhost:4040 | Main user interface |
| Orchestrator API | http://localhost:4041 | REST + SSE API |
| Armory Gateway | http://localhost:4042/mcp | MCP protocol gateway |
| Armory Admin | http://localhost:4043 | Backend management UI |
| Weather MCP | http://localhost:4050 | Weather data server |
| Web Search MCP | http://localhost:4051 | Search server |

## Troubleshooting

### "Connection refused" errors

Services might still be starting. Wait 30 seconds and try again. Check logs:
```bash
docker compose logs orchestrator
```

### LLM errors

Verify your API key is set correctly:
```bash
# Check .env file
cat .env | grep API_KEY
```

### Database errors

If using Docker Compose, the database initializes automatically. For native setup:
```bash
cd forge-armory
uv run alembic upgrade head
```

### Port conflicts

If ports are already in use, either:
1. Stop the conflicting service
2. Or modify ports in `docker-compose.yml`

## Next Steps

- Explore the [Armory Admin UI](http://localhost:4043) to manage MCP backends
- Read the [Architecture Documentation](https://github.com/agentic-forge/blueprint)
- Check the [Project Board](https://github.com/orgs/agentic-forge/projects/1) for current work
