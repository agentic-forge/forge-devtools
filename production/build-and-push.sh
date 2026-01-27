#!/bin/bash
# =============================================================================
# Agentic Forge - Build and Push Images (on VPS)
# =============================================================================
#
# This script syncs code to VPS and builds images there.
#
# Usage:
#   ./build-and-push.sh              # Sync code and build all images
#   ./build-and-push.sh --sync-only  # Only sync code, don't build
#   ./build-and-push.sh --build-only # Only build (assumes code already synced)
#   ./build-and-push.sh v1.0.0       # Build with specific tag
#
# =============================================================================

set -e

# Configuration
VPS_HOST="kashif@hosting_vps"
VPS_PROJECT_DIR="~/stacks/agentic-forge/src"
REGISTRY="localhost:5000"
TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
SYNC_ONLY=false
BUILD_ONLY=false

for arg in "$@"; do
    case $arg in
        --sync-only)
            SYNC_ONLY=true
            ;;
        --build-only)
            BUILD_ONLY=true
            ;;
        --*)
            # Ignore other flags
            ;;
        *)
            # Treat non-flag arguments as tag
            TAG="$arg"
            ;;
    esac
done

# Sync code to VPS
sync_code() {
    log_info "Syncing code to VPS..."

    # Create directory structure on VPS
    ssh "$VPS_HOST" "mkdir -p $VPS_PROJECT_DIR"

    # Sync project files (excluding dev artifacts)
    rsync -avz --delete \
        --exclude='node_modules' \
        --exclude='.venv' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.git' \
        --exclude='dist' \
        --exclude='build' \
        --exclude='.claude-work' \
        --exclude='*.log' \
        --exclude='.env' \
        --exclude='.env.local' \
        "${PROJECT_ROOT}/mcp-servers" \
        "${PROJECT_ROOT}/forge-armory" \
        "${PROJECT_ROOT}/forge-orchestrator" \
        "${PROJECT_ROOT}/forge-ui" \
        "${PROJECT_ROOT}/forge-devtools/production" \
        "${VPS_HOST}:${VPS_PROJECT_DIR}/"

    log_info "Code synced successfully"
}

# Build images on VPS
build_on_vps() {
    log_info "Building images on VPS (tag: ${TAG})..."

    ssh "$VPS_HOST" << EOF
        set -e
        cd $VPS_PROJECT_DIR

        REGISTRY="$REGISTRY"
        TAG="$TAG"

        echo "Building mcp-weather..."
        docker build -t \$REGISTRY/forge-mcp-weather:\$TAG \
            -f production/Dockerfile.python-prod \
            --build-arg SERVICE_DIR=mcp-servers/mcp-weather .
        docker push \$REGISTRY/forge-mcp-weather:\$TAG

        echo "Building mcp-web-search..."
        docker build -t \$REGISTRY/forge-mcp-web-search:\$TAG \
            -f production/Dockerfile.python-prod \
            --build-arg SERVICE_DIR=mcp-servers/mcp-web-search .
        docker push \$REGISTRY/forge-mcp-web-search:\$TAG

        echo "Building orchestrator..."
        docker build -t \$REGISTRY/forge-orchestrator:\$TAG \
            -f production/Dockerfile.python-prod \
            --build-arg SERVICE_DIR=forge-orchestrator .
        docker push \$REGISTRY/forge-orchestrator:\$TAG

        echo "Building armory..."
        docker build -t \$REGISTRY/forge-armory:\$TAG \
            -f production/Dockerfile.armory-prod .
        docker push \$REGISTRY/forge-armory:\$TAG

        echo "Building UI..."
        docker build -t \$REGISTRY/forge-ui:\$TAG \
            -f production/Dockerfile.ui-prod .
        docker push \$REGISTRY/forge-ui:\$TAG

        echo "Building admin UI..."
        docker build -t \$REGISTRY/forge-armory-admin-ui:\$TAG \
            -f production/Dockerfile.admin-ui-prod .
        docker push \$REGISTRY/forge-armory-admin-ui:\$TAG

        echo ""
        echo "All images built and pushed to \$REGISTRY"
        docker images | grep forge
EOF

    log_info "Build complete!"
}

# Main
main() {
    if [ "$BUILD_ONLY" = true ]; then
        build_on_vps
    elif [ "$SYNC_ONLY" = true ]; then
        sync_code
    else
        sync_code
        build_on_vps
    fi

    echo ""
    log_info "=========================================="
    log_info "Done! Tag: ${TAG}"
    log_info "=========================================="
    echo ""
    log_info "Next steps:"
    log_info "  ./deploy.sh        # Deploy the stack"
    log_info "  ./deploy.sh $TAG   # Deploy with specific tag"
}

main
