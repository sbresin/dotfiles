#!/usr/bin/env python3
"""
ashell custom module: GPU usage monitor

Supports AMD, NVIDIA, and Intel GPUs.  On hybrid laptops (NVIDIA + Intel)
both GPUs are shown.  NVIDIA is polled power-aware so that fine-grained
power management can still suspend the dGPU.

Output format (Waybar-style JSON on stdout):
  Single GPU:  {"text":"42%","alt":"amd-ok"}
  Dual GPU:    {"text":"25% / 8%","alt":"nvidia-ok"}
  dGPU asleep: {"text":"zzz / 8%","alt":"nvidia-zzz"}

NVIDIA power-aware polling
──────────────────────────
Calling nvidia-smi wakes the GPU and resets its autosuspend timer, so
polling every 2 s would keep it awake forever.  To avoid this the script
uses a three-state machine:

  MONITORING  – nvidia-smi polled every interval; shows usage %.
                → BACKING_OFF once usage is 0 % for IDLE_POLLS consecutive
                  polls.

  BACKING_OFF – nvidia-smi is NOT called; only sysfs runtime_status is
                read (does not wake the GPU).  Shows "idle" while the
                GPU winds down.
                → SLEEPING once runtime_status becomes "suspended".
                → MONITORING if runtime_status stays "active" for longer
                  than BACKOFF_TIMEOUT_S (something else is using the
                  GPU).

  SLEEPING    – same as BACKING_OFF but shows "zzz".
                → MONITORING once runtime_status flips to "active"
                  (external wake).
"""

from __future__ import annotations

import enum
import json
import os
import shutil
import subprocess
import sys
import threading
import time
from glob import glob
from pathlib import Path

INTERVAL = int(os.environ.get("ASHELL_GPU_POLL_INTERVAL", "2"))

# How many consecutive 0 % polls before we stop calling nvidia-smi.
IDLE_POLLS = int(os.environ.get("ASHELL_GPU_IDLE_POLLS", "5"))

# If the GPU stays "active" this many seconds after we stopped polling,
# assume something else is using it and go back to MONITORING.
BACKOFF_TIMEOUT_S = int(os.environ.get("ASHELL_GPU_BACKOFF_TIMEOUT", "30"))


# ── Helpers ──────────────────────────────────────────────────────────


def emit(text: str, alt: str) -> None:
    print(json.dumps({"text": text, "alt": alt}), flush=True)


def state_for(pct: int) -> str:
    if pct >= 80:
        return "hot"
    if pct >= 50:
        return "warn"
    return "ok"


# ── GPU detection ────────────────────────────────────────────────────


def detect_amd() -> str | None:
    """Return the sysfs path to gpu_busy_percent, or None."""
    for candidate in sorted(glob("/sys/class/drm/card*/device/gpu_busy_percent")):
        if os.access(candidate, os.R_OK):
            return candidate
    return None


def detect_nvidia() -> str | None:
    """Return the sysfs PCI device path for the NVIDIA GPU, or None.

    Only succeeds if nvidia-smi is also on PATH (won't be in nvidia-off
    specialisation).  The sysfs scan itself does NOT wake a suspended GPU.
    """
    if not shutil.which("nvidia-smi"):
        return None
    for dev in sorted(Path("/sys/bus/pci/devices").iterdir()):
        vendor_file = dev / "vendor"
        class_file = dev / "class"
        if not vendor_file.is_file() or not class_file.is_file():
            continue
        vendor = vendor_file.read_text().strip()
        if vendor != "0x10de":
            continue
        cls = class_file.read_text().strip()
        # VGA controller 0x0300xx or 3D controller 0x0302xx
        if cls.startswith("0x0300") or cls.startswith("0x0302"):
            return str(dev)
    return None


def detect_intel() -> bool:
    """Return True if intel_gpu_top is available."""
    return shutil.which("intel_gpu_top") is not None


# ── Readers ──────────────────────────────────────────────────────────


def read_amd(busy_path: str) -> int | None:
    """Read AMD GPU utilisation from sysfs (0-100)."""
    try:
        return int(Path(busy_path).read_text().strip())
    except (ValueError, OSError):
        return None


def read_nvidia_runtime(pci_path: str) -> str:
    """Read NVIDIA runtime power state from sysfs without waking the GPU."""
    try:
        return (Path(pci_path) / "power" / "runtime_status").read_text().strip()
    except OSError:
        return "unknown"


def read_nvidia_usage() -> int | None:
    """Query NVIDIA GPU utilisation via nvidia-smi (0-100).  Wakes the GPU."""
    try:
        out = (
            subprocess.check_output(
                [
                    "nvidia-smi",
                    "--query-gpu=utilization.gpu",
                    "--format=csv,noheader,nounits",
                ],
                timeout=5,
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )
        return int(out)
    except (subprocess.SubprocessError, ValueError):
        return None


class IntelGpuReader:
    """Background reader that streams intel_gpu_top -J and exposes the
    latest Render/3D busy percentage."""

    def __init__(self, interval_s: int) -> None:
        self._lock = threading.Lock()
        self._pct: int | None = None
        self._interval_ms = interval_s * 1000
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    @property
    def pct(self) -> int | None:
        with self._lock:
            return self._pct

    def _run(self) -> None:
        while True:
            try:
                self._stream()
            except Exception:
                pass
            # If intel_gpu_top exits, retry after a delay
            time.sleep(self._interval_ms / 1000)

    def _stream(self) -> None:
        proc = subprocess.Popen(
            ["intel_gpu_top", "-J", "-s", str(self._interval_ms)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        stdout = proc.stdout
        if stdout is None:
            return

        # intel_gpu_top outputs a JSON array: [ {obj}, {obj}, ... ]
        # We incrementally parse top-level objects by tracking brace depth.
        buf: list[str] = []
        depth = 0
        in_string = False
        escape = False

        for chunk in iter(lambda: stdout.read(1), b""):
            if not chunk:
                break
            char = chunk.decode("utf-8", errors="replace")

            if escape:
                buf.append(char)
                escape = False
                continue
            if char == "\\":
                buf.append(char)
                escape = True
                continue
            if char == '"':
                in_string = not in_string
                buf.append(char)
                continue
            if in_string:
                buf.append(char)
                continue

            if char == "{":
                depth += 1
                buf.append(char)
            elif char == "}":
                depth -= 1
                buf.append(char)
                if depth == 0:
                    self._parse_object("".join(buf))
                    buf.clear()
            elif depth > 0:
                buf.append(char)
            # else: ignore characters outside objects ([ , ] whitespace)

        proc.wait()

    def _parse_object(self, raw: str) -> None:
        try:
            obj = json.loads(raw)
            engines = obj.get("engines", {})
            render = engines.get("Render/3D") or engines.get("Render")
            if render:
                with self._lock:
                    self._pct = round(render["busy"])
        except (json.JSONDecodeError, KeyError, TypeError):
            pass


# ── NVIDIA power-aware state machine ────────────────────────────────


class NvState(enum.Enum):
    MONITORING = "monitoring"
    BACKING_OFF = "backing_off"
    SLEEPING = "sleeping"


class NvidiaPoller:
    """Polls NVIDIA GPU usage while respecting runtime power management.

    Uses a three-state machine (see module docstring) so that nvidia-smi
    is only called when the GPU is genuinely in use, allowing it to
    enter D3cold when idle.
    """

    def __init__(self, pci_path: str) -> None:
        self.pci_path = pci_path
        self.state = NvState.SLEEPING
        self.idle_count = 0
        self.backoff_entered: float = 0.0

        # Start in SLEEPING if already suspended, else MONITORING
        runtime = read_nvidia_runtime(pci_path)
        if runtime == "suspended":
            self.state = NvState.SLEEPING
        elif runtime == "active":
            self.state = NvState.MONITORING
            self.idle_count = 0
        else:
            self.state = NvState.SLEEPING

    def poll(self) -> tuple[str, str]:
        """Return (display_text, state_string) for this tick."""
        runtime = read_nvidia_runtime(self.pci_path)

        if self.state == NvState.MONITORING:
            return self._poll_monitoring(runtime)
        elif self.state == NvState.BACKING_OFF:
            return self._poll_backing_off(runtime)
        else:  # SLEEPING
            return self._poll_sleeping(runtime)

    def _poll_monitoring(self, runtime: str) -> tuple[str, str]:
        """Actively polling nvidia-smi."""
        if runtime == "suspended":
            # GPU suspended externally while we were monitoring — unusual
            # but possible (e.g. the last client quit between our polls)
            self.state = NvState.SLEEPING
            return "zzz", "zzz"

        pct = read_nvidia_usage()
        if pct is None:
            return "n/a", "error"

        if pct == 0:
            self.idle_count += 1
            if self.idle_count >= IDLE_POLLS:
                # GPU has been idle long enough — stop poking it
                self.state = NvState.BACKING_OFF
                self.backoff_entered = time.monotonic()
                return "idle", "idle"
        else:
            self.idle_count = 0

        return f"{pct}%", state_for(pct)

    def _poll_backing_off(self, runtime: str) -> tuple[str, str]:
        """Waiting for the GPU to suspend — not calling nvidia-smi."""
        if runtime == "suspended":
            self.state = NvState.SLEEPING
            return "zzz", "zzz"

        # Still active — if it's been too long, something else is using
        # the GPU, so go back to monitoring.
        elapsed = time.monotonic() - self.backoff_entered
        if elapsed > BACKOFF_TIMEOUT_S:
            self.state = NvState.MONITORING
            self.idle_count = 0
            # Do an immediate nvidia-smi read for this tick
            return self._poll_monitoring(runtime)

        return "idle", "idle"

    def _poll_sleeping(self, runtime: str) -> tuple[str, str]:
        """GPU is suspended — only reading sysfs."""
        if runtime == "active":
            # Something external woke the GPU — start monitoring
            self.state = NvState.MONITORING
            self.idle_count = 0
            return self._poll_monitoring(runtime)

        return "zzz", "zzz"


# ── Main loops ───────────────────────────────────────────────────────


def loop_amd_only(busy_path: str) -> None:
    while True:
        pct = read_amd(busy_path)
        if pct is not None:
            emit(f"{pct}%", f"amd-{state_for(pct)}")
        else:
            emit("n/a", "amd-error")
        time.sleep(INTERVAL)


def loop_intel_only(reader: IntelGpuReader) -> None:
    # Emit placeholder immediately, then wait for intel_gpu_top to start
    emit("...", "intel-ok")
    time.sleep(INTERVAL)
    while True:
        pct = reader.pct
        if pct is not None:
            emit(f"{pct}%", f"intel-{state_for(pct)}")
        else:
            emit("n/a", "intel-error")
        time.sleep(INTERVAL)


def loop_dual(nvidia_pci: str, intel: IntelGpuReader | None) -> None:
    """Dual-GPU loop: NVIDIA (power-aware) + Intel."""
    nv = NvidiaPoller(nvidia_pci)

    # Emit an initial reading immediately so ashell shows text right away.
    # Intel won't have data yet, so show "..." for its slot.
    nv_text, nv_state = nv.poll()
    if intel:
        emit(f"{nv_text} / ...", f"nvidia-{nv_state}")
        # Give intel_gpu_top a moment to produce the first sample
        time.sleep(INTERVAL)
    else:
        emit(nv_text, f"nvidia-{nv_state}")

    while True:
        nv_text, nv_state = nv.poll()

        # ── Intel: latest reading from background thread ──
        if intel:
            ipct = intel.pct
            intel_text = f"{ipct}%" if ipct is not None else "n/a"
            text = f"{nv_text} / {intel_text}"
        else:
            text = nv_text

        emit(text, f"nvidia-{nv_state}")
        time.sleep(INTERVAL)


def loop_nvidia_only(nvidia_pci: str) -> None:
    """Single NVIDIA GPU (no Intel iGPU detected)."""
    loop_dual(nvidia_pci, intel=None)


def loop_missing() -> None:
    while True:
        emit("n/a", "missing")
        time.sleep(INTERVAL)


# ── Entry point ──────────────────────────────────────────────────────


def main() -> None:
    amd_path = detect_amd()
    nvidia_pci = detect_nvidia()
    has_intel = detect_intel()

    # AMD only (e.g. Framework laptop)
    if amd_path and not nvidia_pci and not has_intel:
        loop_amd_only(amd_path)
        return

    # Intel only (e.g. nvidia-off specialisation)
    if has_intel and not nvidia_pci and not amd_path:
        loop_intel_only(IntelGpuReader(INTERVAL))
        return

    # NVIDIA + Intel (hybrid laptop)
    if nvidia_pci and has_intel:
        loop_dual(nvidia_pci, IntelGpuReader(INTERVAL))
        return

    # NVIDIA only (unusual — no intel_gpu_top available)
    if nvidia_pci:
        loop_nvidia_only(nvidia_pci)
        return

    # AMD + Intel (unlikely but handle it)
    if amd_path:
        loop_amd_only(amd_path)
        return

    # Nothing found
    loop_missing()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
