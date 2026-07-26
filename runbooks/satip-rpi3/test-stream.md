# Stream Testing Guide

Test the minisatip SAT>IP server before configuring TVHeadend.

## Prerequisites

- minisatip running on satip-gatow
- **mpv** (recommended) or VLC installed on test client
- Network connectivity (local or Tailscale)

> **Note**: mpv is recommended over VLC for SAT>IP streams. VLC's SAT>IP client
> has known issues with certain streams, causing connection failures even when
> the signal is fine. mpv handles SAT>IP more reliably.

## 1. Verify minisatip is Running

### Check Web UI

Open in browser:

| Access | URL |
|--------|-----|
| Local (mDNS) | http://satip-gatow.local:8875 |
| Local (IP) | http://192.168.x.x:8875 |
| Tailscale | http://100.x.x.x:8875 |

You should see the minisatip status page showing:
- Adapter status (2x DVB-C)
- Active streams
- Signal information (when tuned)

### Check from Command Line

```bash
# From any machine on the network
curl -s http://satip-gatow.local:8875/status.html | head -20

# Or check RTSP is responding
curl -s rtsp://satip-gatow.local:5544/ || echo "RTSP port open"
```

## 2. Test Stream: Das Erste (ARD)

### DVB-C Parameters for Das Erste

| Parameter | Value | Notes |
|-----------|-------|-------|
| Transponder | S31 | Vodafone Germany |
| Frequency | 386 MHz | |
| Symbol Rate | 6900 KSym/s | |
| Modulation | 256-QAM | |
| Service ID | 10301 | Das Erste |
| Video PID | 5100 | H.264 |
| Audio PID | 5101 | German, AAC |
| Audio PID | 5102 | German, AC3 |
| Audio PID | 5103 | Audio Description |
| Teletext | 5104 | |

### mpv Command Line (Recommended)

**Basic test (video + main audio):**

```bash
# Local access
mpv "rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102"

# Tailscale access (replace with your Tailscale IP)
mpv "rtsp://100.x.x.x:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102"
```

**All PIDs (video + all audio + teletext):**

```bash
mpv "rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102,5103,5104"
```

### VLC Command Line (Alternative)

> **Warning**: VLC's SAT>IP client has known issues. If VLC fails to play,
> try mpv instead before troubleshooting signal issues.

```bash
vlc "rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102,5103"
```

### VLC GUI Method

1. Open VLC
2. Media → Open Network Stream (Ctrl+N)
3. Enter URL:
   ```
   rtsp://satip-gatow.local:5544/?src=1&freq=386&sr=6900&msys=dvbc&mtype=256qam&pids=0,5101,5102
   ```
4. Click "Play"

### Expected Result

- Video should appear within 2-5 seconds
- For mpv: codec info shown in terminal output
- For VLC: check Tools → Codec Information:
  - Video: H.264/AVC
  - Audio: AAC or AC3
- No stuttering or freezing

## 3. SAT>IP URL Format Reference

### General Format

```
rtsp://<host>:<port>/?src=<n>&freq=<MHz>&sr=<KSym>&msys=dvbc&mtype=<mod>&pids=<pid,pid,...>
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `src` | Source/tuner number | `1` |
| `freq` | Frequency in MHz | `386` |
| `sr` | Symbol rate in KSym/s | `6900` |
| `msys` | Modulation system | `dvbc` |
| `mtype` | Modulation type | `256qam`, `64qam` |
| `pids` | PIDs to stream | `0,5100,5101` |

### PID 0

Always include PID 0 (PAT - Program Association Table). This helps the client understand the stream structure.

### Common Vodafone Germany Modulation

Most Vodafone DVB-C muxes use:
- Symbol rate: 6900 KSym/s
- Modulation: 256-QAM

## 4. Other Test Channels (Vodafone Germany - Berlin)

Here are some other channels to test (frequencies from channels.conf scan):

| Channel | Freq (MHz) | SR | Mod | Video PID | Audio PIDs |
|---------|------------|-----|-----|-----------|------------|
| ZDF HD | 450 | 6900 | 256qam | 6110 | 6120, 6121 |
| arte HD | 418 | 6900 | 256qam | 6661 | 6662, 6663 |
| RTL | 410 | 6900 | 256qam | 7122 | 7123 |
| SAT.1 | 410 | 6900 | 256qam | 7132 | 7133 |
| ProSieben | 546 | 6900 | 256qam | 2201 | 2202 |

**Note**: These PIDs are from a Berlin Vodafone scan - actual values may vary by region.
Use `w-scan-cpp` or TVHeadend's scan feature to discover correct PIDs for your area.

### ZDF HD Test Command

```bash
mpv "rtsp://satip-gatow.local:5544/?src=1&freq=450&sr=6900&msys=dvbc&mtype=256qam&pids=0,6110,6120,6121"
```

### arte HD Test Command

```bash
mpv "rtsp://satip-gatow.local:5544/?src=1&freq=418&sr=6900&msys=dvbc&mtype=256qam&pids=0,6661,6662,6663"
```

## 5. Troubleshooting

### No Video / Black Screen

1. **Check minisatip logs:**
   ```bash
   ssh pi@satip-gatow.local
   sudo journalctl -u minisatip -f
   ```
   Look for tuning errors or "no signal"

2. **Verify tuner detection:**
   ```bash
   ls -la /dev/dvb/
   ```
   Should show `adapter0` and `adapter1`

3. **Check frequency/parameters:**
   - Frequency might be different in your area
   - Try the minisatip web UI to see signal strength

### VLC Shows "Connection Failed"

1. **Check minisatip is running:**
   ```bash
   systemctl status minisatip
   ```

2. **Check ports are open:**
   ```bash
   # On the RPi
   ss -tlnp | grep -E '5544|8875'
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   ```
   Should show `tailscale0 ALLOW`

4. **Test basic connectivity:**
   ```bash
   ping satip-gatow.local
   curl http://satip-gatow.local:8875/
   ```

### Stuttering / Freezing

1. **USB power issue** - check `dmesg` for USB errors; try powered hub if present

2. **Increase buffers** - edit service file:
   ```bash
   sudo systemctl edit minisatip
   ```
   Add:
   ```
   [Service]
   ExecStart=
   ExecStart=/usr/local/bin/minisatip -f -a 0:0:2 -y 5544 -x 8875 -b 752000:11550720
   ```

3. **Check network quality:**
   ```bash
   # If using Tailscale, check for direct connection
   tailscale ping <client-ip>
   ```

### Wrong Channel / No Audio

- PIDs might be incorrect for your region
- Use TVHeadend scan to discover correct PIDs
- Check minisatip web UI for stream details

## 6. Monitoring Active Streams

### minisatip Web UI

Visit http://satip-gatow.local:8875 while streaming to see:
- Active adapters
- Current frequency
- Signal strength/quality
- Active PIDs
- Bitrate

### Command Line

```bash
# Watch minisatip logs in real-time
ssh pi@satip-gatow.local "journalctl -u minisatip -f"
```

## 7. Quick Validation Checklist

- [ ] minisatip web UI accessible at port 8875 (`/status.html`)
- [ ] DVB adapters shown in web UI (2x DVB-C)
- [ ] mpv can connect to RTSP URL and play video
- [ ] Video plays without errors
- [ ] Audio is present
- [ ] No stuttering
- [ ] Tailscale access works (if configured)

Once all checks pass, proceed to [TVHeadend setup](tvheadend-setup.md).
