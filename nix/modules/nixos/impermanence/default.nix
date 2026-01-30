{
  config,
  lib,
  namespace,
  ...
}: let
  cfg = config.${namespace}.impermanence;
in {
  options.${namespace}.impermanence = {
    enable = lib.mkEnableOption "setup impermanence persistent storage";
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/persistent".neededForBoot = true;

    # Fix permissions for /var/lib/private which is required by systemd's DynamicUser feature.
    # Impermanence creates parent directories with mode 0755, but DynamicUser requires 0700.
    systemd.tmpfiles.rules = [
      "z /var/lib/private 0700 root root -"
    ];

    environment.persistence."/persistent" = {
      enable = true; # NB: Defaults to true, not needed
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/flatpak"
        "/var/lib/nixos"
        "/var/lib/sbctl"
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/coredump"
        "/var/cache/tuigreet"
        "/var/lib/private/dnscrypt-proxy"
        "/etc/NetworkManager/system-connections"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    services.openssh = {
      # store hostkeys in persistent storage
      # https://github.com/nix-community/impermanence/issues/192#issuecomment-2425296799
      hostKeys = [
        {
          type = "ed25519";
          path = "/persistent/etc/ssh/ssh_host_ed25519_key";
        }
        {
          type = "rsa";
          bits = 4096;
          path = "/persistent/etc/ssh/ssh_host_rsa_key";
        }
      ];
    };

    virtualisation.docker = {
      daemon.settings = {
        data-root = "/persistent/docker-data";
      };
    };
  };
}
