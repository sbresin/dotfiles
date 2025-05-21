{
  config,
  pkgs,
  lib,
  ...
}: {
  # early KMS
  boot.initrd.kernelModules = ["i915" "nvidia"];
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  # enable HuC firmware for intel-media-driver
  boot.kernelParams = ["i915.enable_guc=2"];

  hardware.graphics = {
    enable = true;
    package = pkgs.unstable.mesa;

    # 32-bit support (e.g for Steam)
    enable32Bit = true;
    package32 = pkgs.unstable.pkgsi686Linux.mesa;

    # add VAAPI drivers for hardware video acceleration
    extraPackages = with pkgs; [
      intel-media-driver
      nvidia-vaapi-driver
    ];
  };

  environment.systemPackages = with pkgs; [
    # useful for debugging PRIME problems
    mesa-demos
    vulkan-tools
  ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  specialisation.nvidia-sync.configuration = {
    environment.etc."specialisation".text = "nvidia-sync";
    environment.sessionVariables.PRIME_MODE = "sync";
    hardware.nvidia = {
      powerManagement.finegrained = lib.mkForce false;
      prime.offload.enable = lib.mkForce false;
      prime.offload.enableOffloadCmd = lib.mkForce false;
      prime.sync.enable = true;
    };
  };
  specialisation.nvidia-reverse.configuration = {
    environment.etc."specialisation".text = "nvidia-reverse";
    environment.sessionVariables.PRIME_MODE = "reverse";
    hardware.nvidia.prime.reverseSync.enable = true;
  };
  specialisation.nvidia-discrete.configuration = {
    environment.etc."specialisation".text = "nvidia-discrete";
    environment.sessionVariables.PRIME_MODE = "discrete";
    hardware.nvidia = {
      powerManagement.enable = lib.mkForce true;
      powerManagement.finegrained = lib.mkForce false;
      prime.offload.enable = lib.mkForce false;
      prime.offload.enableOffloadCmd = lib.mkForce false;
    };
  };
}
