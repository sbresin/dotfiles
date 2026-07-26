#!/bin/bash
# First-run script for Raspberry Pi OS Lite (Trixie)
# Injected via: rpi-imager --cli --first-run-script ./firstrun.sh ...
#
# This script runs once on first boot, then self-deletes.
# 
# Usage:
#   1. Generate password hash: echo 'yourpassword' | openssl passwd -6 -stdin
#   2. Replace PASSWORD_HASH below with the output
#   3. Flash with rpi-imager CLI (see README.md)

set -e

#
# Configuration
#
HOSTNAME="satip-gatow"

# Generate with: echo 'yourpassword' | openssl passwd -6 -stdin
# IMPORTANT: Use single quotes around the hash to preserve $ characters
PASSWORD_HASH='$6$REPLACE_ME$with_your_actual_hash_from_openssl_passwd'

#
# Set hostname
#
echo "$HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts

#
# Enable SSH
#
systemctl enable ssh
systemctl start ssh

#
# Configure pi user
# Trixie no longer has a default pi user with login shell, so we need to:
# 1. Ensure shell is set to /bin/bash (not /usr/sbin/nologin)
# 2. Set the password
#
chsh -s /bin/bash pi
usermod -p "$PASSWORD_HASH" pi

#
# Self-delete
#
rm -f /boot/firstrun.sh
rm -f /boot/firmware/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
sed -i 's| systemd.run.*||g' /boot/firmware/cmdline.txt 2>/dev/null || true

exit 0
