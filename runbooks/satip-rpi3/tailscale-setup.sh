#!/usr/bin/env bash
#
# tailscale-setup.sh - Tailscale Installation for Headless RPi
#
# Installs Tailscale and authenticates with provided auth key.
#
# Usage: sudo ./tailscale-setup.sh <AUTH_KEY>
#
# Get an auth key from: https://login.tailscale.com/admin/settings/keys
#   - Reusable: No (single use is fine)
#   - Ephemeral: No (permanent device)
#   - Pre-approved: Yes (skip manual approval)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check for auth key argument
if [[ $# -lt 1 ]]; then
    log_error "Usage: $0 <AUTH_KEY>"
    echo ""
    echo "Get an auth key from: https://login.tailscale.com/admin/settings/keys"
    echo ""
    echo "Recommended settings:"
    echo "  - Reusable: No"
    echo "  - Ephemeral: No"
    echo "  - Pre-approved: Yes"
    echo "  - Tags: optional (e.g., tag:satip)"
    exit 1
fi

AUTH_KEY="$1"
HOSTNAME="${2:-satip-gatow}"

# Validate auth key format (basic check)
if [[ ! "${AUTH_KEY}" =~ ^tskey-auth- ]]; then
    log_warn "Auth key doesn't start with 'tskey-auth-' - are you sure this is correct?"
fi

# -----------------------------------------------------------------------------
# Step 1: Install Tailscale
# -----------------------------------------------------------------------------
if command -v tailscale &> /dev/null; then
    log_info "Tailscale already installed"
    tailscale version
else
    log_info "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# -----------------------------------------------------------------------------
# Step 2: Enable and Start Tailscaled
# -----------------------------------------------------------------------------
log_info "Enabling tailscaled service..."
systemctl enable tailscaled
systemctl start tailscaled

# Wait for tailscaled to be ready
sleep 2

# -----------------------------------------------------------------------------
# Step 3: Authenticate
# -----------------------------------------------------------------------------
log_info "Authenticating with Tailscale..."
log_info "Hostname: ${HOSTNAME}"

tailscale up \
    --auth-key="${AUTH_KEY}" \
    --hostname="${HOSTNAME}" \
    --accept-dns=false

# -----------------------------------------------------------------------------
# Step 4: Verify Connection
# -----------------------------------------------------------------------------
log_info "Verifying Tailscale connection..."
sleep 3

if tailscale status &> /dev/null; then
    log_info "Tailscale connected successfully!"
    echo ""
    tailscale status
    echo ""
    
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    log_info "Tailscale IPv4: ${TAILSCALE_IP}"
else
    log_error "Tailscale connection failed"
    log_error "Check: sudo tailscale status"
    exit 1
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo -e "${GREEN}Tailscale Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Hostname:      ${HOSTNAME}"
echo "Tailscale IP:  ${TAILSCALE_IP}"
echo ""
echo "Access from any Tailscale client:"
echo "  Web UI:  http://${TAILSCALE_IP}:8875"
echo "  RTSP:    rtsp://${TAILSCALE_IP}:5544"
echo ""
echo "Recommended: Disable key expiry for this device"
echo "  1. Go to https://login.tailscale.com/admin/machines"
echo "  2. Find '${HOSTNAME}'"
echo "  3. Click ... → Disable key expiry"
echo ""
