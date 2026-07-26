# RPi3 SAT>IP Server (satip-gatow)

DVB-C to SAT>IP gateway using Raspberry Pi 3 with Hauppauge WinTV dualHD tuner.
Streams DVB-C channels over Tailscale to a remote TVHeadend server.

## Architecture

```
[Vodafone DVB-C] --> [Hauppauge WinTV dualHD] --> [RPi3]
                            (USB)                    |
                                               [minisatip]
                                            ports 5544/8875
                                                    |
                                             [Tailscale]
                                                    |
                            +-----------------------+----------------------+
                            |                                              |
                     [VLC for testing]                           [TVHeadend]
                                                                 (remote house)
```

## Hardware Requirements

| Item | Notes |
|------|-------|
| Raspberry Pi 3 | Model B or B+ |
| Hauppauge WinTV dualHD | USB DVB-C/T/T2 dual tuner |
| MicroSD card | 16GB+ recommended |
| Coax cable | From Vodafone cable outlet |
| Ethernet | Recommended over WiFi for stability |
| Power supply | **5V 2.5A quality supply** (important!) |
| Powered USB hub | Optional - see note below |

> **Note on USB Power**: The WinTV dualHD draws ~500-800mA depending on tuner
> activity. With a quality 5V/2.5A power supply and no other USB devices, it
> should work directly connected to the RPi3. If you experience tuner dropouts
> or USB errors in `dmesg`, try a powered USB hub as a first troubleshooting step.

## Software Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Raspberry Pi OS Lite | 64-bit (Trixie) | Base OS |
| minisatip | latest (built from source) | SAT>IP server |
| Tailscale | latest | Mesh VPN |
| Si2168 firmware | b40-01 | DVB-C demodulator driver |

## Network Configuration

| Setting | Value |
|---------|-------|
| Hostname | `satip-gatow` |
| Local access | `satip-gatow.local` (mDNS/Avahi) |
| Remote access | Tailscale IP |
| RTSP port | 5544 |
| HTTP/Web UI | 8875 |

## Quick Start (TL;DR)

```bash
# 1. Flash RPi OS Lite 64-bit with firstrun.sh (see "Prepare SD Card" below)
# 2. Connect tuner to RPi USB port, boot up

# 3. Transfer scripts from your machine
scp setup.sh minisatip.service tailscale-setup.sh pi@satip-gatow.local:~

# 4. SSH in and run setup
ssh pi@satip-gatow.local
sudo ./setup.sh

# 5. Setup Tailscale (get auth key from https://login.tailscale.com/admin/settings/keys)
sudo ./tailscale-setup.sh tskey-auth-XXXXX

# 6. Verify
systemctl status minisatip
tailscale status
```

Then test with mpv - see [test-stream.md](test-stream.md).

---

## Step-by-Step Setup

### 1. Prepare SD Card

#### Option A: Using rpi-imager GUI

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select: **Raspberry Pi OS Lite (64-bit)** - Trixie
3. Click gear icon for advanced options:
   - Set hostname: `satip-gatow`
   - Enable SSH (password or key auth)
   - Set username/password
   - Configure WiFi (optional, Ethernet preferred)
   - Set timezone: Europe/Berlin
4. Write to SD card

#### Option B: Using rpi-imager CLI (Wayland/headless)

The GUI has issues running as root on Wayland. Use CLI mode instead:

1. Download the image manually (rpi-imager has a verification bug with URLs):
   ```bash
   curl -L -o raspios-lite.img.xz \
     "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2026-04-21/2026-04-21-raspios-trixie-arm64-lite.img.xz"
   
   # Verify checksum
   sha256sum raspios-lite.img.xz
   # Expected: 4cd31df026fd82243805a326dc0cafd7383f7e3d30c9413e7044d507aae281e2
   ```

2. Create the firstrun script (see [firstrun.sh](firstrun.sh)):
   ```bash
   # Edit firstrun.sh to set your password hash
   # Generate hash: echo 'yourpassword' | openssl passwd -6 -stdin
   ```

3. Flash to SD card:
   ```bash
   sudo ~/Downloads/Raspberry_Pi_Imager-*.AppImage --cli \
     --first-run-script ./firstrun.sh \
     ./raspios-lite.img.xz \
     /dev/sdX  # Replace with your SD card device (check with lsblk)
   ```

> **Note**: The `--first-run-script` option injects a script into the boot
> partition that runs once on first boot, then self-deletes.

### 2. Hardware Setup

1. Insert SD card into RPi3
2. Connect Ethernet cable
3. Connect WinTV dualHD to RPi3 USB port
4. Connect coax cable from wall outlet to WinTV dualHD
5. Power on RPi3

### 3. Initial SSH Access

```bash
# Find RPi on network (or check router DHCP leases)
ping satip-gatow.local

# SSH in
ssh pi@satip-gatow.local
# or
ssh pi@<ip-address>
```

### 4. Run Setup Script

Transfer and run the setup scripts via SSH:

```bash
# From your local machine (in this runbook directory)
scp setup.sh minisatip.service tailscale-setup.sh pi@satip-gatow.local:~

# SSH in
ssh pi@satip-gatow.local

# Run setup
sudo ./setup.sh
```

The script will:
- Update system packages
- Install build dependencies
- Download Si2168 firmware
- Verify tuner detection
- Build minisatip from source
- Install and enable systemd service
- Configure UFW firewall

### 5. Setup Tailscale

1. Generate an auth key at https://login.tailscale.com/admin/settings/keys
   - Reusable: No (single use)
   - Ephemeral: No (permanent device)
   - Pre-approved: Yes
   - Tags: Optional (e.g., `tag:satip`)

2. Run the Tailscale setup script:

```bash
sudo ./tailscale-setup.sh tskey-auth-kXXXXXXXXXXXXX
```

3. Verify connection:

```bash
tailscale status
tailscale ip -4  # Note this IP for remote access
```

4. Disable key expiry (recommended for always-on server):
   - Go to https://login.tailscale.com/admin/machines
   - Find `satip-gatow`
   - Click `...` → Disable key expiry

### 6. Verify Setup

```bash
# Check minisatip is running
systemctl status minisatip

# Check tuner detection
ls -la /dev/dvb/

# Check web UI (from another machine)
curl http://satip-gatow.local:8875/

# Check Tailscale
tailscale status
```

### 7. Test Streaming

See [test-stream.md](test-stream.md) for detailed testing instructions.

Quick test (Das Erste HD on 386 MHz):

```bash
mpv "rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102"
```

> **Note**: Use mpv instead of VLC. VLC's SAT>IP client has known issues with certain streams.

---

## Configuration Reference

### minisatip Command Line

The systemd service runs minisatip with these options:

```bash
/usr/local/bin/minisatip -f -a 0:0:2 -y 5544 -x 8875
```

| Option | Value | Meaning |
|--------|-------|---------|
| `-f` | | Run in foreground (for systemd) |
| `-a 0:0:2` | | 0 DVB-S, 0 DVB-T, 2 DVB-C adapters |
| `-y 5544` | | RTSP port (non-privileged) |
| `-x 8875` | | HTTP/web UI port |

Additional useful options:

| Option | Example | Meaning |
|--------|---------|---------|
| `-e 0-1` | | Enable only adapters 0 and 1 |
| `-b 752000:11550720` | | Increase buffer sizes (if continuity errors) |
| `-l general,http,adapter` | | Enable verbose logging |
| `-d 0` | | Disable SSDP discovery (if not needed) |

### DVB-C Parameters (Vodafone Germany)

| Parameter | Typical Values |
|-----------|----------------|
| Frequency | 114-858 MHz |
| Symbol rate | 6900 KSym/s |
| Modulation | 256-QAM |
| FEC | Auto |

### SAT>IP URL Format (DVB-C)

```
rtsp://<host>:<port>/?src=1&freq=<MHz>&sr=<KSym>&msys=dvbc&mtype=<mod>&pids=<pid,pid,...>
```

Example for Das Erste (S31):
```
rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5100,5101,5104
```

---

## Maintenance

### Service Management

```bash
# Status
sudo systemctl status minisatip

# Restart
sudo systemctl restart minisatip

# Stop
sudo systemctl stop minisatip

# View logs
sudo journalctl -u minisatip -f

# View recent logs
sudo journalctl -u minisatip --since "10 minutes ago"
```

### Updating minisatip

```bash
cd ~/minisatip
git pull
cd build
cmake ..
make -j4
sudo systemctl stop minisatip
sudo make install
sudo systemctl start minisatip
```

### Checking Tuner Status

```bash
# List DVB adapters
ls -la /dev/dvb/

# Check dmesg for tuner messages
dmesg | grep -i dvb

# Check USB devices
lsusb | grep -i hauppauge
```

### Tailscale Management

```bash
# Status
tailscale status

# Check connection type (direct vs relay)
tailscale ping <other-tailscale-ip>

# Network diagnostics
tailscale netcheck

# Disconnect (temporary)
sudo tailscale down

# Reconnect
sudo tailscale up
```

---

## Troubleshooting

### Tuner Not Detected

**Symptoms**: `/dev/dvb/` is empty or missing adapters

**Checks**:
```bash
# Check USB connection
lsusb | grep -i hauppauge
# Should show: Hauppauge WinTV dualHD

# Check kernel messages
dmesg | grep -i -E 'dvb|si2168|usb'

# Check firmware loaded
dmesg | grep -i firmware
```

**Solutions**:
1. Check firmware exists: `ls /lib/firmware/dvb-demod-si2168*`
2. Reboot after firmware installation
3. Try a different USB port on the RPi
4. If persistent, try a powered USB hub (see USB Power Issues below)

### USB Power Issues

**Symptoms**: Tuner detected but disappears, random disconnects, `dmesg` shows USB errors

**Checks**:
```bash
# Look for USB errors
dmesg | grep -i -E 'usb|over-current|disconnect'
```

**Solutions** (try in order):
1. Ensure you have a quality **5V 2.5A power supply** for the RPi
2. Try a different USB port on the RPi
3. Add to `/boot/firmware/config.txt` and reboot:
   ```
   max_usb_current=1
   ```
4. If issues persist, use a **powered USB hub**

### No Signal / Can't Tune

**Symptoms**: minisatip running but no video, "no signal" in logs

**Checks**:
```bash
# Check minisatip logs
sudo journalctl -u minisatip | grep -i signal

# Verify frequency/parameters match your provider
```

**Solutions**:
1. Verify coax cable is connected
2. Check DVB-C parameters (frequency, symbol rate, modulation)
3. Try a different transponder/frequency
4. Check if cable outlet is active

### Continuity Errors / Stuttering / Only One Channel Works

**Symptoms**: Video plays but stutters, logs show CC errors, TS discontinuity errors,
or only some frequencies work while others fail

**Checks**:
```bash
# Check USB transfer mode (isoc = problematic, bulk = good)
dmesg | grep -i "em28xx.*bulk\|em28xx.*isoc"
```

**Solutions**:

1. **Switch to USB bulk mode** (most common fix):
   
   The WinTV dualHD has two USB transfer modes: isochronous (default on older units)
   and bulk. Isoc mode causes artifacts and failures, especially when both tuners
   are active or when switching frequencies.
   
   Check current mode:
   ```bash
   dmesg | grep -i "em28xx.*bulk\|em28xx.*isoc"
   # "dvb set to isoc mode" = problematic
   # "dvb set to bulk mode" = good
   ```
   
   **To switch to bulk mode**, you need the Hauppauge Windows tool - there is no
   Linux-only solution. This permanently changes the device firmware:
   
   1. On a Windows machine, install [WinTV dualHD drivers](https://www.hauppauge.com/pages/support/support_dualhd.html)
   2. Download the [BulkOrIso tool](https://www.hauppauge.de/site/support/support_faq.php?n=FAQ.BulkOrIso)
   3. Run the tool and switch to **Bulk** mode
   4. Plug the device back into the RPi and verify with `dmesg`
   
   > **Note**: Newer devices with d60 firmware often come pre-configured for bulk mode.

2. **Increase buffer sizes** - edit `/etc/systemd/system/minisatip.service`:
   ```
   ExecStart=/usr/local/bin/minisatip -f -a 0:0:2 -y 5544 -x 8875 -R /opt/minisatip/html -b 752000:11550720
   ```

3. Check for USB bandwidth issues (reduce other USB devices)

4. Check Tailscale connection quality: `tailscale ping <client-ip>`

### Tailscale Connection Issues

**Symptoms**: Can't reach satip-gatow via Tailscale IP

**Checks**:
```bash
# On RPi
tailscale status
tailscale netcheck

# Check if using relay (slower) or direct connection
tailscale ping <client-tailscale-ip>
```

**Solutions**:
1. Ensure tailscaled service is running: `systemctl status tailscaled`
2. Re-authenticate if key expired: `sudo tailscale up --auth-key=...`
3. Check firewall: `sudo ufw status`
4. For better direct connections, allow UDP 41641 on router

### minisatip Won't Start

**Symptoms**: Service fails to start

**Checks**:
```bash
sudo systemctl status minisatip
sudo journalctl -u minisatip -n 50
```

**Common causes**:
1. Port already in use - check for other processes: `ss -tlnp | grep -E '5544|8875'`
2. No DVB adapters found - check tuner connection
3. Permission issues - service should run as root

---

## Files in This Runbook

| File | Purpose |
|------|---------|
| [README.md](README.md) | This file - main documentation |
| [firstrun.sh](firstrun.sh) | First-boot script for rpi-imager CLI |
| [setup.sh](setup.sh) | Initial setup script |
| [tailscale-setup.sh](tailscale-setup.sh) | Tailscale installation |
| [minisatip.service](minisatip.service) | Systemd unit file |
| [test-stream.md](test-stream.md) | Stream testing guide (mpv/VLC) |
| [tvheadend-setup.md](tvheadend-setup.md) | TVHeadend configuration |

---

## References

- [minisatip GitHub](https://github.com/catalinii/minisatip)
- [Hauppauge WinTV dualHD Linux support](https://www.hauppauge.com/pages/support/support_linux.html)
- [Tailscale documentation](https://tailscale.com/kb/)
- [SAT>IP specification](https://www.satip.info/)
- [LinuxTV DVB wiki](https://linuxtv.org/wiki/)
