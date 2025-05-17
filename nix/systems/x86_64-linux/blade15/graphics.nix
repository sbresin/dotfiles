{
  config,
  pkgs,
  ...
}: {
  # early KMS
  boot.initrd.kernelModules = ["i915" "nvidia"];
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  # enable HuC firmware for intel-media-driver
  boot.kernelParams = ["i915.enable_guc=2"];

  hardware.graphics = {
    enable = true;

    # 32-bit support (e.g for Steam)
    enable32Bit = true;

    # add VAAPI drivers for hardware video acceleration
    extraPackages = with pkgs; [
      intel-media-driver
      nvidia-vaapi-driver
    ];
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
}
