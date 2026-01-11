#!/bin/bash
# =============================================================================
# Agentic Forge - Development Environment Stop Script
# =============================================================================
#
# Stops all services by killing the tmux session.
#
# Usage:
#   ./dev-stop.sh
#
# =============================================================================

SESSION="forge"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if tmux has-session -t $SESSION 2>/dev/null; then
    tmux kill-session -t $SESSION
    echo -e "${GREEN}Stopped all Agentic Forge services${NC}"
else
    echo -e "${YELLOW}No running session found (session: $SESSION)${NC}"
fi
