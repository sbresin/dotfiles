#!/usr/bin/env bash
#
# setup.sh - RPi3 SAT>IP Server Setup
#
# Installs dependencies, firmware, builds minisatip, configures systemd and firewall.
# Idempotent - safe to run multiple times.
#
# Usage: sudo ./setup.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINISATIP_DIR="/opt/minisatip"
MINISATIP_BIN="/usr/local/bin/minisatip"

# -----------------------------------------------------------------------------
# Step 1: System Update
# -----------------------------------------------------------------------------
log_info "Updating system packages..."
apt update
apt upgrade -y

# -----------------------------------------------------------------------------
# Step 2: Install Dependencies
# -----------------------------------------------------------------------------
log_info "Installing build dependencies..."
apt install -y \
    build-essential \
    cmake \
    git \
    libssl-dev \
    ufw \
    avahi-daemon

# -----------------------------------------------------------------------------
# Step 3: Install DVB Firmware
# -----------------------------------------------------------------------------
log_info "Installing Si2168 firmware for WinTV dualHD..."

FIRMWARE_DIR="/lib/firmware"
FIRMWARE_FILE="dvb-demod-si2168-b40-01.fw"
FIRMWARE_URL="https://github.com/OpenELEC/dvb-firmware/raw/master/firmware/${FIRMWARE_FILE}"

if [[ -f "${FIRMWARE_DIR}/${FIRMWARE_FILE}" ]]; then
    log_info "Firmware already installed, skipping download"
else
    log_info "Downloading firmware..."
    wget -q -O "${FIRMWARE_DIR}/${FIRMWARE_FILE}" "${FIRMWARE_URL}" || {
        log_warn "Primary download failed, trying alternative source..."
        wget -q -O "${FIRMWARE_DIR}/${FIRMWARE_FILE}" \
            "https://www.hauppauge.com/linux/${FIRMWARE_FILE}" || {
            log_error "Failed to download firmware"
            exit 1
        }
    }
    log_info "Firmware installed to ${FIRMWARE_DIR}/${FIRMWARE_FILE}"
fi

# Also get the d60 variant (some hardware revisions use this)
FIRMWARE_FILE_D60="dvb-demod-si2168-d60-01.fw"
if [[ ! -f "${FIRMWARE_DIR}/${FIRMWARE_FILE_D60}" ]]; then
    log_info "Downloading Si2168 D60 firmware variant..."
    wget -q -O "${FIRMWARE_DIR}/${FIRMWARE_FILE_D60}" \
        "https://github.com/CoreELEC/dvb-firmware/raw/master/firmware/${FIRMWARE_FILE_D60}" || \
        log_warn "D60 firmware download failed (may not be needed)"
fi

# -----------------------------------------------------------------------------
# Step 4: Verify Tuner Detection
# -----------------------------------------------------------------------------
log_info "Checking for DVB adapters..."

# Reload modules to pick up new firmware
modprobe -r si2168 2>/dev/null || true
modprobe si2168 2>/dev/null || true
sleep 2

if [[ -d /dev/dvb ]]; then
    ADAPTERS=$(ls -d /dev/dvb/adapter* 2>/dev/null | wc -l)
    log_info "Found ${ADAPTERS} DVB adapter(s)"
    ls -la /dev/dvb/
else
    log_warn "No DVB adapters found at /dev/dvb/"
    log_warn "This could mean:"
    log_warn "  - Tuner is not connected"
    log_warn "  - Firmware was just installed (try rebooting)"
    log_warn "  - USB power issue (try powered hub if problems persist)"
    log_warn ""
    log_warn "Continuing with setup - reboot and re-check after completion"
fi

# Check USB for Hauppauge device
if lsusb | grep -qi hauppauge; then
    log_info "Hauppauge USB device detected"
    lsusb | grep -i hauppauge
else
    log_warn "No Hauppauge USB device found"
    log_warn "Ensure WinTV dualHD is connected to a USB port"
fi

# -----------------------------------------------------------------------------
# Step 5: Build minisatip
# -----------------------------------------------------------------------------
log_info "Building minisatip from source..."

if [[ -d "${MINISATIP_DIR}" ]]; then
    log_info "Updating existing minisatip source..."
    cd "${MINISATIP_DIR}"
    git fetch origin
    git reset --hard origin/master
else
    log_info "Cloning minisatip repository..."
    git clone https://github.com/catalinii/minisatip.git "${MINISATIP_DIR}"
    cd "${MINISATIP_DIR}"
fi

# Build
log_info "Compiling minisatip..."
rm -rf build
mkdir build
cd build
cmake ..
make -j"$(nproc)"

# Install binary
log_info "Installing minisatip binary..."
cp minisatip "${MINISATIP_BIN}"
chmod +x "${MINISATIP_BIN}"

log_info "minisatip installed to ${MINISATIP_BIN}"

# -----------------------------------------------------------------------------
# Step 6: Install Systemd Service
# -----------------------------------------------------------------------------
log_info "Installing systemd service..."

SERVICE_FILE="/etc/systemd/system/minisatip.service"

if [[ -f "${SCRIPT_DIR}/minisatip.service" ]]; then
    cp "${SCRIPT_DIR}/minisatip.service" "${SERVICE_FILE}"
else
    # Create service file inline if not found
    cat > "${SERVICE_FILE}" << 'EOF'
[Unit]
Description=MiniSATIP DVB-C Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/minisatip -f -a 0:0:2 -y 5544 -x 8875 -R /opt/minisatip/html
Restart=always
RestartSec=5
# Increase priority for smoother streaming
Nice=-10

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable minisatip

# Start service if DVB adapters are present
if [[ -d /dev/dvb ]]; then
    log_info "Starting minisatip service..."
    systemctl restart minisatip
    sleep 2
    if systemctl is-active --quiet minisatip; then
        log_info "minisatip is running"
    else
        log_warn "minisatip failed to start - check: journalctl -u minisatip"
    fi
else
    log_warn "Not starting minisatip - no DVB adapters found"
    log_warn "Start manually after reboot: sudo systemctl start minisatip"
fi

# -----------------------------------------------------------------------------
# Step 7: Configure Firewall
# -----------------------------------------------------------------------------
log_info "Configuring UFW firewall..."

# Reset UFW to defaults
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (important!)
ufw allow ssh

# Allow all traffic on Tailscale interface
ufw allow in on tailscale0

# Allow local network access to minisatip (optional - comment out for Tailscale-only)
# Uncomment the following lines if you want local LAN access without Tailscale:
# ufw allow from 192.168.0.0/16 to any port 5544 proto tcp
# ufw allow from 192.168.0.0/16 to any port 8875 proto tcp

# Enable firewall
ufw --force enable

log_info "Firewall configured - Tailscale interface allowed"

# -----------------------------------------------------------------------------
# Step 8: Enable Avahi/mDNS
# -----------------------------------------------------------------------------
log_info "Enabling Avahi for mDNS (.local) discovery..."
systemctl enable avahi-daemon
systemctl start avahi-daemon

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Hostname:     $(hostname)"
echo "mDNS:         $(hostname).local"
echo "Web UI:       http://$(hostname).local:8875"
echo "RTSP:         rtsp://$(hostname).local:5544"
echo ""

if [[ -d /dev/dvb ]]; then
    echo "DVB Adapters: $(ls -d /dev/dvb/adapter* 2>/dev/null | wc -l) found"
else
    echo -e "${YELLOW}DVB Adapters: None detected - reboot may be required${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Run tailscale-setup.sh to join your Tailnet"
echo "  2. Test with VLC (see test-vlc.md)"
echo ""

if ! systemctl is-active --quiet minisatip; then
    echo -e "${YELLOW}Note: minisatip is not running. After reboot:${NC}"
    echo "  sudo systemctl start minisatip"
fi

echo ""
log_info "If tuner wasn't detected, reboot now: sudo reboot"
