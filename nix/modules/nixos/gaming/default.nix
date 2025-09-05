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
      packages = with pkgs.unstable; [game-devices-udev-rules];
      extraRules = ''
        # enable access to wii Bluetooth chip for dolphin-emu passthrough
        SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0305", TAG+="uaccess", GROUP="plugdev", MODE="0666"
      '';
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

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-cachyos_x86_64_v3
        proton-ge-bin
      ];
      gamescopeSession = {
        enable = true;
        args = [
          "-W 1920"
          "-H 1080"
          "--fullscreen"
          "--xwayland-count 2"
          "--adaptive-sync"
          "--hdr-enabled"
          "--hdr-itm-enabled"
          "--mangoapp"
        ];
        steamArgs = [
          "-pipewire-dmabuf"
          "-tenfoot"
        ];
      };
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    # gamescope session wants this
    # services.seatd.enable = true;

    # friidump needs setuid bit
    security.wrappers = {
      friidump = {
        setuid = true;
        owner = "root";
        group = "cdrom";
        permissions = "u+wrx,g+x";
        source = "${pkgs.${namespace}.friidump}/bin/friidump";
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
      # nvtopPackages.nvidia
      # rom tools
      mame.tools
      # pkgs.${namespace}.rusty-psn
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
        "com.discordapp.Discord"
      ];
    };
  };
}
