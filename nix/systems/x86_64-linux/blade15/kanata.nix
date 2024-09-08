{
  lib,
  pkgs,
  ...
}: let
  # copy config files to nix store
  kanata-config = pkgs.stdenvNoCC.mkDerivation {
    name = "kanata-config";
    src = lib.snowfall.fs.get-file ".config/kanata";
    postInstall = ''
      mkdir $out
      cp -v *.kbd $out
    '';
  };
in {
  hardware.uinput.enable = true;
  services.kanata.enable = true;
  services.kanata.keyboards."all".configFile = "${kanata-config}/kanata.kbd";
  systemd.services.kanata-all.serviceConfig = {
    # breaks the service for me, PermissionDenied trying to register any keyboard input device
    DynamicUser = lib.mkForce false;
    ProtectSystem = "strict";
  };
}
