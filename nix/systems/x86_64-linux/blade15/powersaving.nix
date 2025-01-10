{
  lib,
  pkgs,
  ...
}: {
  services.thermald.enable = true;

  services.tlp.enable = true;
  services.tlp.settings = {
    NMI_WATCHDOG = 0;
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    DISK_DEVICES = "nvme-NVMe_CA5-8D512_0021044000VT nvme-Samsung_SSD_970_EVO_Plus_2TB_S4J4NM0R801122Z";
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
}
