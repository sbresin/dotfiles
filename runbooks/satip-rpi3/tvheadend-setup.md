# TVHeadend SAT>IP Configuration

Configure TVHeadend to use satip-gatow as a remote DVB-C tuner source over Tailscale.

## Prerequisites

- satip-gatow running and tested with mpv (see [test-stream.md](test-stream.md))
- TVHeadend installed on remote server (or Docker for testing)
- Both machines on same Tailnet (or local network)

## Quick Test with Docker

For testing TVHeadend without a permanent installation, use Docker:

```bash
# Create persistent config directory
mkdir -p ~/.config/tvheadend-test

# Get satip-gatow's Tailscale IP
SATIP_IP=$(ssh pi@satip-gatow.local "tailscale ip -4")

# Run TVHeadend with SAT>IP client enabled
docker run -d \
  --name tvheadend-test \
  --network=host \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e "RUN_OPTS=--satip_xml http://${SATIP_IP}:8875/desc.xml" \
  -v ~/.config/tvheadend-test:/config \
  lscr.io/linuxserver/tvheadend:latest

# Access web UI at http://localhost:9981
# Tuners should appear automatically in Configuration → DVB Inputs → TV Adapters
```

**Important**: The `--satip_xml` flag requires a **space** (not `=`) before the URL when
using the linuxserver image's `RUN_OPTS` environment variable.

### Cleanup After Testing

```bash
docker stop tvheadend-test
docker rm tvheadend-test
# Optionally remove config: rm -rf ~/.config/tvheadend-test
```

## Architecture

```
[satip-gatow]                        [TVHeadend Server]
   RPi3                                  (remote)
     |                                      |
[minisatip] ------- Tailscale ---------- [TVHeadend]
 :5544 RTSP                              SAT>IP Client
 :8875 HTTP                                  |
                                        [Clients]
                                      Kodi, ATV, etc.
```

## 1. Add SAT>IP Network

### Navigate to Network Configuration

```
Configuration → DVB Inputs → Networks
```

### Add New Network

Click **Add** and select: **SAT>IP DVB-C Network**

> **No Auto-Discovery Over Tailscale**: SAT>IP normally uses SSDP/UPnP for
> automatic server discovery, but multicast doesn't traverse Tailscale. You
> must manually specify the server URL using the Tailscale IP address.

Get satip-gatow's Tailscale IP first:
```bash
ssh pi@satip-gatow.local "tailscale ip -4"
```

### Network Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Enabled** | ✓ | |
| **Network name** | `satip-gatow` | Descriptive name |
| **Maximum # input streams** | 2 | WinTV dualHD has 2 tuners |
| **Maximum timeout (seconds)** | 30 | Increase if on slow connection |
| **Discovery type** | Specify URL | Auto-discovery won't work over Tailscale |
| **URL** | `rtsp://100.x.x.x:5544` | Replace with actual Tailscale IP |
| **Satellite positions** | 1 | Required even for DVB-C |

For local network testing, you can use `rtsp://satip-gatow.local:5544` instead.

### Predefined Muxes (Recommended)

Instead of manually adding muxes, use predefined scan files:

| Field | Value |
|-------|-------|
| **Pre-defined muxes** | `Germany - Vodafone/Kabel Deutschland` |

Or if that's not available:
- `Germany - de-Berlin`
- `Germany - Generic DVB-C`

Click **Create** to save the network.

## 2. Add TV Adapter

After creating the network, TVHeadend should auto-discover the SAT>IP tuners.

### Check Adapter Detection

```
Configuration → DVB Inputs → TV Adapters
```

You should see entries like:
- `SAT>IP DVB-C #0 (100.x.x.x:5544)`
- `SAT>IP DVB-C #1 (100.x.x.x:5544)`

If not visible, check:
1. minisatip is running: `systemctl status minisatip`
2. URL is correct in network settings
3. Firewall allows Tailscale traffic

### Adapter Settings

Click on each adapter and configure:

| Field | Value | Notes |
|-------|-------|-------|
| **Enabled** | ✓ | |
| **Networks** | `satip-gatow` | Select your network |

## 3. Bandwidth Optimization (Critical!)

By default, TVHeadend requests the **full transport stream mux** from the SAT>IP server. A typical DVB-C mux is ~38 Mbit/s, while a single HD channel is only ~5-8 Mbit/s.

**This is critical for Tailscale streaming** - you want to minimize bandwidth.

### Configure PID Filtering

#### Option A: Per-Adapter Setting

```
Configuration → DVB Inputs → TV Adapters → [click adapter]
```

| Field | Value | Effect |
|-------|-------|--------|
| **Full Mux Rx mode** | `Never` | Only requested PIDs |

#### Option B: Network-Level Setting

```
Configuration → DVB Inputs → Networks → [satip-gatow]
```

| Field | Value |
|-------|-------|
| **SAT>IP full mux request** | Disabled |

### Verify PID Filtering

When streaming a channel, check the minisatip web UI at `http://satip-gatow:8875`:

- **Without PID filtering**: Shows full mux bitrate (~38 Mbit/s)
- **With PID filtering**: Shows only active PIDs (~5-8 Mbit/s per HD channel)

## 4. Initial Mux Scan

### Start the Scan

```
Configuration → DVB Inputs → Networks → [satip-gatow]
```

Set:
| Field | Value |
|-------|-------|
| **Idle scan muxes** | ✓ |
| **Skip initial scan** | ✗ (unchecked) |

Click **Save**.

### Monitor Scan Progress

```
Configuration → DVB Inputs → Muxes
```

Watch as TVHeadend:
1. Tunes to each frequency from the predefined list
2. Scans for services (channels)
3. Updates mux status (OK, FAIL, etc.)

Scan time: 5-15 minutes depending on number of muxes.

### Check Discovered Services

```
Configuration → DVB Inputs → Services
```

You should see discovered channels like:
- Das Erste (ARD)
- ZDF
- RTL, SAT.1, ProSieben, etc.

## 5. Map Services to Channels

### Auto-Map All Services

```
Configuration → DVB Inputs → Services
```

1. Click **Map services** dropdown
2. Select **Map selected services to channels**
3. Or use **Map all services** for everything

### Selective Mapping

To map only specific channels:

1. Sort by "Service name"
2. Select desired services (Ctrl+click for multiple)
3. Click **Map services** → **Map selected services to channels**

### Verify Channel List

```
Configuration → Channel/EPG → Channels
```

Mapped channels appear here. You can:
- Edit channel names
- Set channel numbers
- Assign to channel tags (groups)

## 6. Das Erste Manual Mux (Reference)

If you need to manually add the S31 mux for Das Erste:

```
Configuration → DVB Inputs → Muxes → Add
```

| Field | Value |
|-------|-------|
| **Network** | satip-gatow |
| **Frequency** | 386000000 |
| **Symbol rate** | 6900000 |
| **Modulation** | QAM-256 |
| **Original network ID** | 1 |
| **Transport stream ID** | 1051 |

After adding, the mux will be scanned and Das Erste (service ID 10301) will appear in Services.

## 7. EPG Configuration (Optional)

### Enable Over-the-Air EPG

```
Configuration → Channel/EPG → EPG Grabber Modules
```

Enable:
- **EIT: DVB Grabber** - for German EPG data

### Trigger EPG Grab

```
Configuration → Channel/EPG → EPG Grabber
```

Click **Re-run internal EPG grabbers**.

## 8. Test Playback

### TVHeadend Web UI

```
http://<tvheadend-server>:9981
```

Go to **Electronic Program Guide**, find a channel, click ▶ to stream.

### VLC via TVHeadend

```bash
vlc "http://<tvheadend-server>:9981/stream/channel/<channel-uuid>"
```

Or use TVHeadend's built-in playlist:
```bash
vlc "http://<tvheadend-server>:9981/playlist/channels.m3u"
```

### Kodi

1. Install **TVHeadend HTSP Client** add-on
2. Configure with TVHeadend server IP
3. Channels appear in TV section

## 9. Bandwidth Verification

### Check Actual Bandwidth Usage

On satip-gatow while streaming:

```bash
# Watch minisatip output
ssh pi@satip-gatow.local "journalctl -u minisatip -f"

# Or check web UI for active PIDs and bitrate
```

### Expected Bandwidth

| Scenario | Bandwidth |
|----------|-----------|
| Full mux (wrong!) | ~38 Mbit/s |
| Single HD channel | ~5-8 Mbit/s |
| Single SD channel | ~2-4 Mbit/s |
| Two HD channels | ~10-16 Mbit/s |

If seeing full mux bandwidth, revisit the PID filtering settings in section 3.

## 10. Troubleshooting

### "No input sources available"

- Check adapter is enabled and assigned to network
- Check minisatip is running on satip-gatow
- Verify URL in network settings

### Scan finds no services

- Check signal at satip-gatow (minisatip web UI)
- Verify coax cable is connected
- Try different predefined mux list
- Try manual mux entry with known good frequency

### Playback stutters

1. Check PID filtering is enabled (section 3)
2. Check Tailscale connection quality:
   ```bash
   tailscale ping <satip-gatow-tailscale-ip>
   ```
3. If relay connection, bandwidth may be limited
4. Check for direct Tailscale connection:
   ```bash
   tailscale status
   # Should show "direct" not "relay"
   ```

### High bandwidth despite PID filtering

- Ensure "Full Mux Rx mode" is set to "Never"
- Restart TVHeadend after changing settings
- Check minisatip logs for actual PID requests

### Adapter shows offline

1. SSH to satip-gatow and check:
   ```bash
   systemctl status minisatip
   ls /dev/dvb/
   ```
2. Restart minisatip:
   ```bash
   sudo systemctl restart minisatip
   ```
3. In TVHeadend, disable and re-enable the adapter

## Quick Reference

| Setting | Location | Value |
|---------|----------|-------|
| SAT>IP URL | Networks | `rtsp://<tailscale-ip>:5544` |
| PID filtering | TV Adapters | Full Mux Rx: Never |
| Predefined muxes | Networks | Germany - Vodafone |
| Max streams | Networks | 2 |

## Summary

1. Add SAT>IP network with Tailscale IP URL
2. **Enable PID filtering** (Full Mux Rx: Never)
3. Select predefined muxes for Vodafone Germany
4. Run scan to discover services
5. Map services to channels
6. Verify bandwidth is ~5-8 Mbit/s per channel, not 38 Mbit/s
