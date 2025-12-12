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
  };

  config = lib.mkIf cfg.enable {
    services.thermald.enable = true;

    services.tlp.enable = true;
    services.tlp.settings = {
      NMI_WATCHDOG = 0;

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      # TODO: second drive for blade
      DISK_DEVICES = "nvme0n1";
      # DISK_DEVICES = "nvme-NVMe_CA5-8D512_0021044000VT nvme-Samsung_SSD_970_EVO_Plus_2TB_S4J4NM0R801122Z";
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
