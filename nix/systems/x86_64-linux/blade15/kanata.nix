{lib, ...}: let
  # use config files from flake repo
  config-dir = lib.snowfall.fs.get-file "stow/dot-config/kanata";
in {
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
}
