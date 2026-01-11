#!/bin/bash
# =============================================================================
# Agentic Forge - Clone All Repositories
# =============================================================================
#
# Clones all Agentic Forge repositories into the parent directory.
# Run this from the forge-devtools directory.
#
# Usage:
#   ./scripts/clone-repos.sh
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the parent directory (where all repos should live)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVTOOLS_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$DEVTOOLS_DIR")"

echo -e "${BLUE}Agentic Forge - Repository Setup${NC}"
echo ""
echo -e "Workspace: ${GREEN}$PARENT_DIR${NC}"
echo ""

# Repository list
REPOS=(
    "forge-ui"
    "forge-orchestrator"
    "forge-armory"
)

MCP_REPOS=(
    "mcp-weather"
    "mcp-web-search"
)

# Clone function
clone_repo() {
    local repo=$1
    local target=$2
    local url="https://github.com/agentic-forge/${repo}.git"

    if [ -d "$target" ]; then
        echo -e "  ${YELLOW}[skip]${NC} $repo (already exists)"
    else
        echo -e "  ${GREEN}[clone]${NC} $repo"
        git clone --quiet "$url" "$target"
    fi
}

# Clone main repositories
echo -e "${BLUE}Cloning core services...${NC}"
for repo in "${REPOS[@]}"; do
    clone_repo "$repo" "$PARENT_DIR/$repo"
done

# Clone MCP servers into mcp-servers directory
echo ""
echo -e "${BLUE}Cloning MCP servers...${NC}"
mkdir -p "$PARENT_DIR/mcp-servers"
for repo in "${MCP_REPOS[@]}"; do
    clone_repo "$repo" "$PARENT_DIR/mcp-servers/$repo"
done

# Optional: Clone blueprint for documentation
echo ""
echo -e "${BLUE}Cloning documentation...${NC}"
clone_repo "blueprint" "$PARENT_DIR/blueprint"

echo ""
echo -e "${GREEN}Done!${NC} All repositories cloned to $PARENT_DIR"
echo ""
echo "Next steps:"
echo "  1. cp .env.example .env"
echo "  2. Edit .env and add your API keys"
echo "  3. docker compose up"
echo ""
echo "Or for native development:"
echo "  ./scripts/dev-start.sh"
