#!/bin/bash
# =============================================================================
# Agentic Forge - Development Environment Status
# =============================================================================
#
# Shows the status of all services and their ports.
#
# Usage:
#   ./dev-status.sh
#
# =============================================================================

# Port assignments (must match dev-start.sh)
PORT_UI=4040
PORT_ORCHESTRATOR=4041
PORT_ARMORY=4042
PORT_MCP_WEATHER=4050
PORT_MCP_SEARCH=4051

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SESSION="forge"

echo -e "${BLUE}Agentic Forge - Service Status${NC}"
echo "==============================="
echo ""

# Check tmux session
if tmux has-session -t $SESSION 2>/dev/null; then
    echo -e "tmux session: ${GREEN}running${NC} (session: $SESSION)"
else
    echo -e "tmux session: ${RED}not running${NC}"
fi
echo ""

# Function to check if port is listening
check_port() {
    local name=$1
    local port=$2
    if ss -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${GREEN}●${NC} $name (:$port) - ${GREEN}listening${NC}"
    else
        echo -e "  ${RED}○${NC} $name (:$port) - ${RED}not listening${NC}"
    fi
}

echo "Core Services:"
check_port "forge-ui" $PORT_UI
check_port "forge-orchestrator" $PORT_ORCHESTRATOR
check_port "forge-armory" $PORT_ARMORY
echo ""

echo "MCP Servers:"
check_port "mcp-weather" $PORT_MCP_WEATHER
check_port "mcp-web-search" $PORT_MCP_SEARCH
echo ""

# Quick health checks if services are up
echo "Health Checks:"
if curl -s --max-time 2 "http://localhost:$PORT_ORCHESTRATOR/health" > /dev/null 2>&1; then
    echo -e "  ${GREEN}●${NC} Orchestrator health: ${GREEN}OK${NC}"
else
    echo -e "  ${YELLOW}○${NC} Orchestrator health: ${YELLOW}unavailable${NC}"
fi

if curl -s --max-time 2 "http://localhost:$PORT_ARMORY/health" > /dev/null 2>&1; then
    echo -e "  ${GREEN}●${NC} Armory health: ${GREEN}OK${NC}"
else
    echo -e "  ${YELLOW}○${NC} Armory health: ${YELLOW}unavailable${NC}"
fi
echo ""

echo "Commands:"
echo "  ./dev-start.sh   Start all services"
echo "  ./dev-stop.sh    Stop all services"
echo "  tmux attach -t forge   Attach to running session"
