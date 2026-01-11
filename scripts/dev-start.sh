#!/bin/bash
# =============================================================================
# Agentic Forge - Development Environment Startup Script
# =============================================================================
#
# Starts all services in a single tmux session with tiled panes.
# See dev-ports.md for port allocation and architecture details.
#
# Usage:
#   ./dev-start.sh          Start all services
#   ./dev-start.sh --help   Show this help
#
# tmux Navigation:
#   Ctrl+b q      Show pane numbers (then press number to jump)
#   Ctrl+b o      Cycle to next pane
#   Ctrl+b ;      Toggle between last two panes
#   Ctrl+b z      Zoom current pane (toggle fullscreen)
#   Ctrl+b d      Detach (services keep running)
#   Ctrl+b x      Kill current pane
#   Ctrl+b s      Switch between sessions (if you have multiple)
#   Ctrl+b (      Previous session
#   Ctrl+b )      Next session
#
# Note: If run from inside tmux, this script will switch to the forge
# session instead of creating a nested session.
#
# To reattach (from outside tmux):
#   tmux attach -t forge
#
# To stop all services:
#   ./dev-stop.sh
#   or: tmux kill-session -t forge
#
# =============================================================================

set -e

# Configuration
SESSION="forge"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVTOOLS_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$DEVTOOLS_DIR")"  # Parent of forge-devtools (workspace root)

# Port assignments (see dev-ports.md)
PORT_UI=4040
PORT_ORCHESTRATOR=4041
PORT_ARMORY=4042
PORT_ARMORY_ADMIN_UI=4043
PORT_MCP_WEATHER=4050
PORT_MCP_SEARCH=4051

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    head -40 "$0" | tail -37
    exit 0
fi

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is not installed${NC}"
    echo "Install with: sudo apt install tmux"
    exit 1
fi

if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: uv is not installed${NC}"
    echo "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
echo -e "${BLUE}Starting Agentic Forge development environment...${NC}"
echo ""
echo -e "Port allocation:"
echo -e "  ${GREEN}forge-ui${NC}            :$PORT_UI"
echo -e "  ${GREEN}forge-orchestrator${NC}  :$PORT_ORCHESTRATOR"
echo -e "  ${GREEN}forge-armory${NC}        :$PORT_ARMORY"
echo -e "  ${GREEN}armory-admin-ui${NC}     :$PORT_ARMORY_ADMIN_UI"
echo -e "  ${GREEN}mcp-weather${NC}         :$PORT_MCP_WEATHER"
echo -e "  ${GREEN}mcp-web-search${NC}      :$PORT_MCP_SEARCH"
echo ""

# Kill existing session if running
if tmux has-session -t $SESSION 2>/dev/null; then
    echo -e "${YELLOW}Killing existing session...${NC}"
    tmux kill-session -t $SESSION
fi

# Create new session (detached)
tmux new-session -d -s $SESSION -c "$BASE_DIR"

# Create 6 panes with splits
# Layout:
#   ┌──────────┬──────────┬──────────┐
#   │ weather  │  search  │  armory  │
#   ├──────────┼──────────┼──────────┤
#   │ admin-ui │  orch.   │    ui    │
#   └──────────┴──────────┴──────────┘

# Split horizontally into 3 columns for top row
tmux split-window -t $SESSION -h
tmux split-window -t $SESSION -h

# Select leftmost pane and split vertically
tmux select-pane -t $SESSION:0.0
tmux split-window -t $SESSION -v

# Select middle-top pane and split vertically
tmux select-pane -t $SESSION:0.2
tmux split-window -t $SESSION -v

# Select right-top pane and split vertically
tmux select-pane -t $SESSION:0.4
tmux split-window -t $SESSION -v

# Apply tiled layout for even distribution
tmux select-layout -t $SESSION tiled

# Pane assignments after tiled layout (may vary, so we use send-keys carefully)
# Re-select and label each pane

# Set pane titles (requires tmux 2.6+)
tmux select-pane -t $SESSION:0.0 -T "mcp-weather"
tmux select-pane -t $SESSION:0.1 -T "mcp-search"
tmux select-pane -t $SESSION:0.2 -T "armory"
tmux select-pane -t $SESSION:0.3 -T "armory-admin-ui"
tmux select-pane -t $SESSION:0.4 -T "orchestrator"
tmux select-pane -t $SESSION:0.5 -T "ui"

# Send commands to each pane
# Pane 0: MCP Weather Server
tmux send-keys -t $SESSION:0.0 "cd '$BASE_DIR/mcp-servers/mcp-weather' && echo -e '${GREEN}[mcp-weather :$PORT_MCP_WEATHER]${NC}' && uv run python -m forge_mcp_weather.server --port $PORT_MCP_WEATHER" C-m

# Pane 1: MCP Web Search Server
tmux send-keys -t $SESSION:0.1 "cd '$BASE_DIR/mcp-servers/mcp-web-search' && echo -e '${GREEN}[mcp-web-search :$PORT_MCP_SEARCH]${NC}' && uv run python -m forge_mcp_web_search.server --port $PORT_MCP_SEARCH" C-m

# Pane 2: Armory Gateway (wait for MCP servers)
tmux send-keys -t $SESSION:0.2 "cd '$BASE_DIR/forge-armory' && echo -e '${GREEN}[forge-armory :$PORT_ARMORY]${NC} (waiting 2s for MCP servers...)' && sleep 2 && uv run armory serve --reload --port $PORT_ARMORY" C-m

# Pane 3: Armory Admin UI (wait for Armory)
tmux send-keys -t $SESSION:0.3 "cd '$BASE_DIR/forge-armory/admin-ui' && echo -e '${GREEN}[armory-admin-ui :$PORT_ARMORY_ADMIN_UI]${NC} (waiting 4s for Armory...)' && sleep 4 && bun run dev" C-m

# Pane 4: Orchestrator (wait for Armory)
tmux send-keys -t $SESSION:0.4 "cd '$BASE_DIR/forge-orchestrator' && echo -e '${GREEN}[forge-orchestrator :$PORT_ORCHESTRATOR]${NC} (waiting 4s for Armory...)' && sleep 4 && uv run orchestrator serve --reload --port $PORT_ORCHESTRATOR" C-m

# Pane 5: UI (wait for Orchestrator)
tmux send-keys -t $SESSION:0.5 "cd '$BASE_DIR/forge-ui' && echo -e '${GREEN}[forge-ui :$PORT_UI]${NC} (waiting 6s for Orchestrator...)' && sleep 6 && bun run dev -- --port $PORT_UI" C-m

# Select first pane
tmux select-pane -t $SESSION:0.0

echo -e "${GREEN}Session '$SESSION' created with 6 panes${NC}"
echo ""

# Attach or switch to session (handle being inside tmux already)
if [[ -n "$TMUX" ]]; then
    echo -e "Switching to session... (${YELLOW}Ctrl+b d${NC} to detach)"
    echo ""
    tmux switch-client -t $SESSION
else
    echo -e "Attaching to session... (${YELLOW}Ctrl+b d${NC} to detach)"
    echo ""
    tmux attach-session -t $SESSION
fi
