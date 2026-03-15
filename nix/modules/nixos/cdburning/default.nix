{
  config,
  lib,
  pkgs,

  ...
}: let
  cfg = config.sebe.cdburning;
in {
  options.sebe.cdburning = {
    enable = lib.mkEnableOption "install software for cd burning";
  };

  config = lib.mkIf cfg.enable {
    # enable cd burning (needed for k3b)
    security.wrappers = {
      cdrdao = {
        setuid = true;
        owner = "root";
        group = "cdrom";
        permissions = "u+wrx,g+x";
        source = "${pkgs.cdrdao}/bin/cdrdao";
      };
      cdrecord = {
        setuid = true;
        owner = "root";
        group = "cdrom";
        permissions = "u+wrx,g+x";
        source = "${pkgs.cdrtools}/bin/cdrecord";
      };
    };

    environment.systemPackages = with pkgs.unstable; [
      brasero
      dvdplusrwtools
    ];
  };
}
