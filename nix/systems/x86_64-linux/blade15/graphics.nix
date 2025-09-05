{
  config,
  pkgs,
  lib,
  ...
}: {
  # early KMS
  boot.initrd.kernelModules = ["i915"];
  boot.extraModulePackages = [];

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

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    open = true;
    modesetting.enable = false;
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
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  specialisation.nvidia-off.configuration = {
    services.udev.extraRules = ''
      # Remove NVIDIA USB xHCI Host Controller devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
      # Remove NVIDIA USB Type-C UCSI devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
      # Remove NVIDIA Audio devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
      # Remove NVIDIA VGA/3D controller devices
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
    '';
    boot.blacklistedKernelModules = ["nouveau" "nvidia" "nvidia_drm" "nvidia_modeset"];
  };

  specialisation.nvidia-sync.configuration = {
    environment.etc."specialisation".text = "nvidia-sync";
    environment.sessionVariables.PRIME_MODE = "sync";
    hardware.nvidia = {
      powerManagement.finegrained = lib.mkForce false;
      modesetting.enable = lib.mkForce true;
      prime = {
        offload.enable = lib.mkForce false;
        offload.enableOffloadCmd = lib.mkForce false;
        sync.enable = true;
      };
    };
  };
  specialisation.nvidia-discrete.configuration = {
    environment.etc."specialisation".text = "nvidia-discrete";
    environment.sessionVariables.PRIME_MODE = "discrete";
    hardware.nvidia = {
      powerManagement.enable = lib.mkForce true;
      powerManagement.finegrained = lib.mkForce false;
      modesetting.enable = lib.mkForce true;
      prime.offload.enable = lib.mkForce false;
      prime.offload.enableOffloadCmd = lib.mkForce false;
    };
  };
}
