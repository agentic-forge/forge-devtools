# Agentic Forge - Production Deployment

Deploy the Agentic Forge stack to a Docker Swarm cluster with Traefik.

## Architecture

```
Public Internet
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  Traefik                                                │
│  agentic-forge.compulife.com.pk → forge-ui:80           │
└─────────────────────────────────────────────────────────┘
      │
      ▼ (traefik-net overlay network)
┌─────────────────────────────────────────────────────────┐
│  Docker Swarm Stack: agentic-forge                      │
│                                                         │
│  ┌──────────┐     ┌─────────────┐     ┌─────────────┐  │
│  │ forge-ui │────▶│ orchestrator│────▶│   armory    │  │
│  │   nginx  │     │    :4041    │     │    :4042    │  │
│  │   :80    │     └─────────────┘     └──────┬──────┘  │
│  └──────────┘                                │         │
│       │ /api proxy                           │         │
│       └──────────────────────────────────────┘         │
│                                              │         │
│                    ┌─────────────────────────┼─────┐   │
│                    ▼                         ▼     ▼   │
│              ┌──────────┐    ┌────────────┐ ┌───────┐  │
│              │ postgres │    │mcp-weather │ │mcp-web│  │
│              │  :5432   │    │   :4050    │ │ :4051 │  │
│              └──────────┘    └────────────┘ └───────┘  │
│                                                         │
│              ┌─────────────────┐                        │
│              │ armory-admin-ui │  (SSH tunnel only)     │
│              │      :80        │                        │
│              └─────────────────┘                        │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- VPS with Docker Swarm and Traefik configured
- `traefik-net` overlay network created
- SSH access to VPS
- Docker registry running on VPS (localhost:5000)

## Quick Start

### 1. Build and Push Images

The build script syncs code to VPS and builds images there:

```bash
cd forge-devtools/production
./build-and-push.sh
```

### 2. Configure Environment on VPS

```bash
# Copy env template
scp .env.example.production kashif@hosting_vps:~/stacks/agentic-forge/.env.production

# SSH in and edit
ssh kashif@hosting_vps
cd ~/stacks/agentic-forge
nano .env.production  # Add your API keys and set a strong DB password
```

### 3. Deploy

```bash
./deploy.sh
```

## Commands

### Build

```bash
# Sync code and build all images on VPS
./build-and-push.sh

# Build with specific tag
./build-and-push.sh v1.0.0

# Only sync code (no build)
./build-and-push.sh --sync-only

# Only build (assumes code already synced)
./build-and-push.sh --build-only
```

### Deploy

```bash
# Deploy latest
./deploy.sh

# Deploy specific tag
./deploy.sh v1.0.0

# Check status
./deploy.sh --status

# View logs
./deploy.sh --logs ui
./deploy.sh --logs orchestrator

# Remove stack
./deploy.sh --remove
```

### Admin UI Access

The admin UI is not exposed publicly. Access via SSH tunnel:

```bash
# Terminal 1: Start tunnel
ssh -L 14043:localhost:14043 kashif@hosting_vps

# Browser: Open http://localhost:14043
```

## Files

| File | Purpose |
|------|---------|
| `docker-compose.prod.yml` | Swarm stack definition |
| `Dockerfile.python-prod` | Python services (weather, search, orchestrator) |
| `Dockerfile.armory-prod` | Armory with Alembic migrations |
| `Dockerfile.ui-prod` | Chat UI (nginx + API proxy) |
| `Dockerfile.admin-ui-prod` | Admin UI (nginx + API proxy) |
| `build-and-push.sh` | Sync code to VPS and build images |
| `deploy.sh` | Deploy/manage stack on VPS |
| `.env.example.production` | Environment template |

## Updating

To deploy updates:

```bash
# Build and push new images (syncs code and builds on VPS)
./build-and-push.sh

# Deploy (will rolling-update services)
./deploy.sh
```

## Troubleshooting

### Services not starting

Check logs:
```bash
./deploy.sh --logs <service>
```

### Database issues

Check postgres logs and ensure password is set:
```bash
./deploy.sh --logs postgres
```

### SSL certificate issues

Traefik auto-provisions Let's Encrypt certificates. Check Traefik logs on VPS:
```bash
ssh kashif@hosting_vps
docker service logs kh_traefik --tail 100
```

### MCP backends show 0 tools

If the weather or web-search MCP backends show `tool_count: 0` after deployment, it's likely a race condition where armory tried to connect before the MCP services were ready.

**Fix:** Delete and re-add the backends via admin API:

```bash
ssh kashif@hosting_vps
ARMORY=$(docker ps -q -f name=agentic-forge_armory.1)

# Delete broken backends
docker exec $ARMORY curl -s -X DELETE http://localhost:4042/admin/backends/weather
docker exec $ARMORY curl -s -X DELETE http://localhost:4042/admin/backends/web-search

# Re-add them
docker exec $ARMORY curl -s -X POST http://localhost:4042/admin/backends \
  -H "Content-Type: application/json" \
  -d '{"name":"weather","url":"http://mcp-weather:4050/mcp","enabled":true,"timeout":30.0,"prefix":"weather","mount_enabled":true}'

docker exec $ARMORY curl -s -X POST http://localhost:4042/admin/backends \
  -H "Content-Type: application/json" \
  -d '{"name":"web-search","url":"http://mcp-web-search:4051/mcp","enabled":true,"timeout":30.0,"prefix":"search","mount_enabled":true}'

# Verify
docker exec $ARMORY curl -s http://localhost:4042/admin/backends | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f\"{b['name']}: tools={b['tool_count']}\") for b in d['backends']]"
```

### BYOK (Bring Your Own Key) not working

Users provide their own LLM API keys via the UI. Common issues:

1. **Wrong API key format**: OpenRouter keys start with `sk-or-v1-...`, OpenAI keys start with `sk-proj-...` or `sk-...`. Make sure you're using the right key for the selected provider.

2. **Key not being sent**: Check browser dev tools → Network tab to verify `X-LLM-Key` header is being sent with requests.

3. **Debug key reception**: Temporarily add logging to orchestrator to see what key prefix is received:
   ```python
   # In orchestrator.py, around the "Creating agent" log
   key_prefix = api_key[:8] + "..." if api_key else "(none)"
   logger.info("Creating agent", ..., key_prefix=key_prefix)
   ```

## Fresh Deployment vs Update

### Fresh Deployment

On a completely new deployment:

1. Ensure `traefik-net` overlay network exists
2. Backends are auto-registered by `init-backends` service
3. The init service waits for MCP services to be healthy before registering

### Updating Existing Deployment

```bash
./build-and-push.sh   # Sync code and rebuild images
./deploy.sh           # Rolling update - preserves database and backends
```

Database and registered backends persist across updates (stored in Docker volumes).
