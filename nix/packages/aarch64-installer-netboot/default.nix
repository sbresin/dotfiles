{inputs, ...}: let
  nixosSystem = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      (inputs.nixpkgs + "/nixos/modules/installer/netboot/netboot-minimal.nix")
      ../../systems/aarch64-linux/pi-installer/default.nix
    ];
  };

  build = nixosSystem.config.system.build;
in
  nixosSystem.pkgs.symlinkJoin {
    name = "netboot";
    paths = [
      build.netbootRamdisk
      build.kernel
      build.netbootIpxeScript
    ];
  }
