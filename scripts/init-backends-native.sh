#!/bin/sh
# =============================================================================
# Initialize MCP Backends (Native/tmux Development)
# =============================================================================
# Registers default MCP backends with Armory for native development.
# Run this after starting services with dev-start.sh.
#
# Usage:
#   ./init-backends-native.sh              # Uses default localhost URLs
#   ARMORY_URL=http://host:port ./init-backends-native.sh
#
# Backends:
#   - weather:     Our Open-Meteo based weather server (localhost:4050)
#   - web-search:  Our Brave Search based server (localhost:4051)
#   - huggingface: Huggingface's hosted MCP server (remote)
# =============================================================================

set -e

ARMORY_URL="${ARMORY_URL:-http://localhost:4042}"

echo "Waiting for Armory to be ready at ${ARMORY_URL}..."
until curl -sf "${ARMORY_URL}/health" > /dev/null 2>&1; do
    echo "  Armory not ready, waiting..."
    sleep 2
done
echo "Armory is ready!"

# Check if backends already exist
EXISTING=$(curl -sf "${ARMORY_URL}/admin/backends" | grep -o '"total":[0-9]*' | cut -d: -f2)
if [ "$EXISTING" -gt 0 ]; then
    echo "Backends already registered (${EXISTING} found). Skipping initialization."
    echo "To re-register, delete existing backends first via Admin UI or API."
    exit 0
fi

echo "Registering MCP backends..."

# Register weather backend
echo "  Registering weather backend..."
curl -sf -X POST "${ARMORY_URL}/admin/backends" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "weather",
        "url": "http://localhost:4050/mcp",
        "enabled": true,
        "timeout": 30.0,
        "prefix": "weather",
        "mount_enabled": true
    }' > /dev/null

# Register web-search backend
echo "  Registering web-search backend..."
curl -sf -X POST "${ARMORY_URL}/admin/backends" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "web-search",
        "url": "http://localhost:4051/mcp",
        "enabled": true,
        "timeout": 30.0,
        "prefix": "search",
        "mount_enabled": true
    }' > /dev/null

# Register Huggingface backend (remote hosted MCP server)
echo "  Registering huggingface backend..."
curl -sf -X POST "${ARMORY_URL}/admin/backends" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "huggingface",
        "url": "https://huggingface.co/mcp",
        "enabled": true,
        "timeout": 30.0,
        "prefix": "hf",
        "mount_enabled": true
    }' > /dev/null

echo "MCP backends registered successfully!"
echo "  - weather     -> http://localhost:4050/mcp (prefix: weather)"
echo "  - web-search  -> http://localhost:4051/mcp (prefix: search)"
echo "  - huggingface -> https://huggingface.co/mcp (prefix: hf)"
