{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.powersaving;
in {
  options.${namespace}.powersaving = {
    enable = lib.mkEnableOption "enable powersaving";

    diskDevices = lib.mkOption {
      type = lib.types.str;
      default = "nvme0n1";
      description = "Disk devices for TLP power management";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp.enable = true;
    services.tlp.settings = {
      NMI_WATCHDOG = 0;

      # Set governor to powersave - this is required for amd-pstate-epp / intel_pstate
      # to enable hardware-managed dynamic frequency scaling and expose all EPP options.
      # Despite the name, "powersave" does NOT lock to min frequency - it allows the
      # CPU hardware to autonomously select frequencies based on the EPP hint below.
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

      # Turbo boost control - disable on battery to reduce heat and save power
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      DISK_DEVICES = cfg.diskDevices;
      # already disabled in BIOS
      WOL_DISABLE = "N";
      # stay cold on AC as well
      RUNTIME_PM_ON_AC = "auto";
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_DRIVER_DENYLIST = "mei_me nouveau radeon"; # xhci_hcd
    };

    services.power-profiles-daemon.enable = lib.mkForce false;

    boot.kernel.sysctl = {
      "vm.dirty_writeback_centisecs" = 1500;
      # "vm.laptop_mode" = 5;
    };

    environment.systemPackages = with pkgs; [
      # s0ix debugging
      bc
      powertop
      pciutils
      tinyxxd
      acpica-tools
      linuxPackages.turbostat
      s0ix-selftest-tool
    ];
  };
}
