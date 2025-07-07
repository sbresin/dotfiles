{
  config,
  pkgs,
  lib,
  ...
}: let
  gpl_symbols_linux_615_patch = pkgs.fetchpatch {
    url = "https://github.com/CachyOS/kernel-patches/raw/914aea4298e3744beddad09f3d2773d71839b182/6.15/misc/nvidia/0003-Workaround-nv_vm_flags_-calling-GPL-only-code.patch";
    hash = "sha256-YOTAvONchPPSVDP9eJ9236pAPtxYK5nAePNtm2dlvb4=";
    stripLen = 1;
    extraPrefix = "kernel/";
  };
  nvidia_package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "575.57.08";
    openSha256 = "sha256-DOJw73sjhQoy+5R0GHGnUddE6xaXb/z/Ihq3BKBf+lg=";
    sha256_64bit = "sha256-KqcB2sGAp7IKbleMzNkB3tjUTlfWBYDwj50o3R//xvI=";
    settingsSha256 = "sha256-AIeeDXFEo9VEKCgXnY3QvrW5iWZeIVg4LBCeRtMs5Io=";
    persistencedSha256 = "sha256-Len7Va4HYp5r3wMpAhL4VsPu5S0JOshPFywbO7vYnGo=";
    usePersistenced = true;
    patches = [gpl_symbols_linux_615_patch];
  };
in {
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
    package = nvidia_package;
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
