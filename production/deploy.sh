#!/bin/bash
# =============================================================================
# Agentic Forge - Deploy to VPS
# =============================================================================
#
# Deploys or updates the agentic-forge stack on the VPS.
#
# Usage:
#   ./deploy.sh              # Deploy with latest tag
#   ./deploy.sh v1.0.0       # Deploy with specific tag
#   ./deploy.sh --status     # Check stack status
#   ./deploy.sh --logs       # View logs
#   ./deploy.sh --remove     # Remove the stack
#
# =============================================================================

set -e

# Configuration
VPS_HOST="kashif@hosting_vps"
STACK_NAME="agentic-forge"
STACK_DIR="~/stacks/agentic-forge"
TAG="${1:-latest}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show stack status
show_status() {
    log_info "Stack status:"
    ssh "$VPS_HOST" "docker stack services $STACK_NAME" 2>/dev/null || echo "Stack not deployed"
    echo ""
    log_info "Service details:"
    ssh "$VPS_HOST" "docker stack ps $STACK_NAME --no-trunc" 2>/dev/null || true
}

# Show logs
show_logs() {
    local service="${2:-}"
    if [ -n "$service" ]; then
        log_info "Logs for ${STACK_NAME}_${service}:"
        ssh "$VPS_HOST" "docker service logs ${STACK_NAME}_${service} --tail 100 -f"
    else
        log_info "Available services:"
        ssh "$VPS_HOST" "docker stack services $STACK_NAME --format '{{.Name}}'" 2>/dev/null
        echo ""
        log_info "Usage: ./deploy.sh --logs <service>"
        log_info "Example: ./deploy.sh --logs ui"
    fi
}

# Remove the stack
remove_stack() {
    log_warn "Removing stack: $STACK_NAME"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh "$VPS_HOST" "docker stack rm $STACK_NAME"
        log_info "Stack removed"
    else
        log_info "Cancelled"
    fi
}

# Setup VPS directory
setup_vps() {
    log_info "Setting up VPS directory..."
    ssh "$VPS_HOST" "mkdir -p $STACK_DIR"

    log_info "Copying compose file..."
    scp "${SCRIPT_DIR}/docker-compose.prod.yml" "${VPS_HOST}:${STACK_DIR}/"

    # Check if .env.production exists on VPS
    if ! ssh "$VPS_HOST" "test -f ${STACK_DIR}/.env.production"; then
        log_warn ".env.production not found on VPS"
        log_warn "Please create it manually or copy from local:"
        log_warn "  scp ${SCRIPT_DIR}/.env.production ${VPS_HOST}:${STACK_DIR}/"
        exit 1
    fi
}

# Deploy the stack
deploy() {
    log_info "Deploying stack: $STACK_NAME (tag: $TAG)"

    setup_vps

    log_info "Deploying to Docker Swarm..."
    # Source .env.production to get env vars (Docker Swarm doesn't read .env files automatically)
    ssh "$VPS_HOST" "cd $STACK_DIR && set -a && source .env.production && set +a && IMAGE_TAG=$TAG docker stack deploy -c docker-compose.prod.yml $STACK_NAME"

    log_info "Waiting for services to start..."
    sleep 5

    show_status

    echo ""
    log_info "=========================================="
    log_info "Deployment complete!"
    log_info "=========================================="
    log_info ""
    log_info "Public URL: https://agentic-forge.compulife.com.pk"
    log_info ""
    log_info "Admin UI (via SSH tunnel):"
    log_info "  1. ssh -L 14043:localhost:14043 ${VPS_HOST}"
    log_info "  2. Open http://localhost:14043"
}

# Main
case "${1:-}" in
    --status|-s)
        show_status
        ;;
    --logs|-l)
        show_logs "$@"
        ;;
    --remove|-r)
        remove_stack
        ;;
    --help|-h)
        echo "Usage: ./deploy.sh [options]"
        echo ""
        echo "Options:"
        echo "  <tag>        Deploy with specific image tag (default: latest)"
        echo "  --status     Show stack status"
        echo "  --logs       View service logs"
        echo "  --remove     Remove the stack"
        echo "  --help       Show this help"
        ;;
    *)
        deploy
        ;;
esac
