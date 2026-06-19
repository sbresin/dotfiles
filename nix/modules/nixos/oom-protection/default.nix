{
  config,
  lib,

  ...
}:
let
  cfg = config.sebe.oom-protection;
in
{
  options.sebe.oom-protection = {
    enable = lib.mkEnableOption "OOM protection with tuned systemd-oomd and zram";

    zram = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable zram compressed swap in front of disk swap.";
      };

      memoryPercent = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "zram device size as a percentage of total RAM.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # --- systemd-oomd ----------------------------------------------------------
    # NixOS enables systemd-oomd by default, but leaves the slice monitors off.
    # Without these, oomd never actually kills anything — the kernel OOM killer
    # (which fires far too late) is the only line of defence.
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;

      settings.OOM = {
        # Kill when 90 % of swap is consumed (hard backstop).
        SwapUsedLimit = "90%";
        # Kill the highest-pressure cgroup when memory pressure exceeds 60 %
        # sustained for 20 s.  This is the Fedora default — at 60 % pressure the
        # system is already heavily stalled and unlikely to recover on its own.
        DefaultMemoryPressureLimit = "60%";
        DefaultMemoryPressureDurationUSec = "20s";
      };
    };

    # --- zram swap -------------------------------------------------------------
    # Compressed in-RAM swap sits above disk swap in priority.  With zstd the
    # typical compression ratio is 2-3x, so 50 % of RAM ≈ 100-150 % effective
    # extra capacity before disk swap is touched.
    zramSwap = lib.mkIf cfg.zram.enable {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.zram.memoryPercent;
      priority = 100; # higher than disk swap (default -1/-2)
    };

    # --- sysctl tuning ---------------------------------------------------------
    boot.kernel.sysctl = {
      # With zram present the kernel should prefer compressing anonymous pages
      # into zram (cheap, in-RAM) over dropping file caches.  The kernel docs
      # recommend 150-200 with zram; Fedora / ChromeOS / Android all use >=180.
      "vm.swappiness" = lib.mkIf cfg.zram.enable 180;

      # Disable watermark boosting — reduces unnecessary direct-reclaim stalls
      # on systems with enough swap headroom.
      "vm.watermark_boost_factor" = 0;

      # Wake kswapd earlier so reclaim is asynchronous rather than synchronous.
      # Default is 10 (= 0.1 % of zone), 125 = 1.25 % — gives more runway.
      "vm.watermark_scale_factor" = 125;

      # zram is random-access; readahead (page-cluster) wastes effort.
      "vm.page-cluster" = lib.mkIf cfg.zram.enable 0;
    };
  };
}
