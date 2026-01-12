#!/bin/sh
# =============================================================================
# Initialize MCP Backends
# =============================================================================
# Registers the default MCP backends (weather, web-search) with Armory.
# This script is run as an init container after Armory is healthy.
# =============================================================================

set -e

ARMORY_URL="${ARMORY_URL:-http://armory:4042}"

echo "Waiting for Armory to be ready..."
until curl -sf "${ARMORY_URL}/health" > /dev/null 2>&1; do
    echo "  Armory not ready, waiting..."
    sleep 2
done
echo "Armory is ready!"

# Check if backends already exist
EXISTING=$(curl -sf "${ARMORY_URL}/admin/backends" | grep -o '"total":[0-9]*' | cut -d: -f2)
if [ "$EXISTING" -gt 0 ]; then
    echo "Backends already registered (${EXISTING} found). Skipping initialization."
    exit 0
fi

echo "Registering MCP backends..."

# Register weather backend
echo "  Registering weather backend..."
curl -sf -X POST "${ARMORY_URL}/admin/backends" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "weather",
        "url": "http://mcp-weather:4050/mcp",
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
        "url": "http://mcp-web-search:4051/mcp",
        "enabled": true,
        "timeout": 30.0,
        "prefix": "search",
        "mount_enabled": true
    }' > /dev/null

echo "MCP backends registered successfully!"
echo "  - weather (4 tools)"
echo "  - web-search (5 tools)"
