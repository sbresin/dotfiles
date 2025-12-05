{
  config,
  lib,
  namespace,
  ...
}: let
  cfg = config.${namespace}.kanata;
  # use config files from flake repo
  config-dir = lib.snowfall.fs.get-file "stow/dot-config/kanata";
in {
  options.${namespace}.kanata = {
    enable = lib.mkEnableOption "enable kanata globally";
  };

  config = lib.mkIf cfg.enable {
    hardware.uinput.enable = true;

    services.kanata = {
      enable = true;
      keyboards."all".configFile = "${config-dir}/kanata.kbd";
    };
    systemd.services.kanata-all.serviceConfig = {
      # breaks the service for me, PermissionDenied trying to register any keyboard input device
      DynamicUser = lib.mkForce false;
      ProtectSystem = "strict";
    };
  };
}

