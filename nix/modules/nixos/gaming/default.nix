{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.modules.gaming;
in {
  options.modules.gaming = {
    enable = lib.mkEnableOption "install gaming stuff";
  };

  config = lib.mkIf cfg.enable {
    # add direct user access to game controllers
    services.udev = {
      enable = true;
      packages = with pkgs; [game-devices-udev-rules];
    };

    # enable combining joycons to single controller
    services.joycond = {
      enable = true;
      package = pkgs.${namespace}.joycond;
    };

    # enable game mode
    programs.gamemode = {
      enable = true;
      settings = {
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };

    environment.systemPackages = with pkgs.unstable; [
      # Emulators
      dolphin-emu
      mgba
      ryubing
      pkgs.${namespace}.duckstation
      # os tools
      mangohud
      evtest-qt
      nvtopPackages.intel
      nvtopPackages.nvidia
      # rom tools
      mame.tools
      pkgs.${namespace}.rusty-psn
      pkgs.${namespace}.threedstool
    ];

    services.flatpak = {
      enable = true;
      overrides = {
        "com.discordapp.Discord".Context.sockets = ["x11"]; # No Wayland support
        "com.valvesoftware.Steam".Context.sockets = ["x11"]; # No Wayland support
      };
      packages = [
        # emulators
        "net.rpcs3.RPCS3"
        "info.cemu.Cemu"
        "org.flycast.Flycast"
        # proprietary
        "com.valvesoftware.Steam"
        "com.discordapp.Discord"
      ];
    };
  };
}
