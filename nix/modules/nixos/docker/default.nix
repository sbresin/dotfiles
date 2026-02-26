{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.docker;
in {
  options.${namespace}.docker = {
    enable = lib.mkEnableOption "Docker virtualisation with buildx support";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;

    # Docker Compose's Bake integration looks for buildx in standard system
    # paths (/usr/lib/docker/cli-plugins, etc.) which don't exist on NixOS.
    # The docker CLI package patches its own plugin lookup at build time, but
    # the compose plugin doesn't get the same patch. Create a system-wide
    # symlink so compose can find buildx for Bake builds.
    systemd.tmpfiles.rules = [
      "d /usr/lib/docker/cli-plugins 0755 root root -"
      "L+ /usr/lib/docker/cli-plugins/docker-buildx - - - - ${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx"
    ];
  };
}
