{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.secureboot;
in {
  options.${namespace}.secureboot = {
    enable = lib.mkEnableOption "setup secureboot";
  };

  config = lib.mkIf cfg.enable {
    # lanzaboote replaces systemd-boot
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # for TPM based LUKS decryption we need systemd
    boot.initrd.systemd.enable = true;

    environment.systemPackages = with pkgs.unstable; [
      sbctl
      sbsigntool
    ];
  };
}
