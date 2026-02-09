{
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}: let
  cfg = config.${namespace}.desktop;
in {
  options.${namespace}.desktop = {
    enable = lib.mkEnableOption "install graphical desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable touchpad support (enabled default in most desktopManagers).
    services.libinput.enable = true;

    # default to Wayland for chromium/electron apps
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.hyprland = {
      enable = true;
      # TODO: withUWSM should use start-hyprland, not Hyprland directly
      # waiting for upstream fix, using programs.uwsm directly instead
      # withUWSM = true;
      xwayland.enable = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors.hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "${pkgs.unstable.hyprland}/bin/start-hyprland";
      };
    };

    programs.xwayland = {
      enable = true;
      package = pkgs.unstable.xwayland;
    };

    # needed by uwsm
    services.dbus.implementation = "broker";

    # fix localctl xkb layout listing
    services.xserver.exportConfiguration = true;

    programs.hyprlock = {
      enable = true;
      package = pkgs.unstable.hyprlock;
    };



    # bluetooth gui and applet
    services.blueman.enable = true;

    # network gui and applet
    programs.nm-applet.enable = true;

    # backend for walker application launcher
    # Wrapper script reads the full user session PATH (set up by UWSM) before
    # starting elephant, so it can find and launch all apps (system, home-manager,
    # flatpak). NixOS's auto-generated PATH in the unit file is too minimal.
    systemd.user.services.elephant = {
      description = "Elephant application launcher backend";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Restart = "always";
        RestartSec = 10;
        ExecStart = toString (pkgs.writeShellScript "elephant-wrapper" ''
          eval "$(${pkgs.systemd}/bin/systemctl --user show-environment | ${pkgs.gnugrep}/bin/grep ^PATH=)"
          exec ${pkgs.unstable.elephant}/bin/elephant "$@"
        '');
      };
    };

    # TODO: nerdshade, lule,
    services.upower.enable = true;
    programs.dconf.enable = true;
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    # show samba shares in nautilus
    services.samba-wsdd = {
      enable = true;
      discovery = true;
    };

    programs.gnome-disks = {
      enable = true;
    };

    services.gnome.sushi.enable = true;

    # hyprland ecosystem services and status bar managed via home-manager
    home-manager.sharedModules = [
      {
        programs.ashell = {
          enable = true;
          package = pkgs.unstable.ashell;
          systemd.enable = true;
        };

        services.hypridle = {
          enable = true;
          package = pkgs.unstable.hypridle;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "~/.config/hypr/scripts/monitor_toggle.sh && hyprctl dispatch dpms on";
            };
            listener = [
              {
                timeout = 150; # 2.5min
                on-timeout = "brightnessctl -s set 10";
                on-resume = "brightnessctl -r";
              }
              {
                timeout = 300; # 5min
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 330; # 5.5min
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
              }
              {
                timeout = 450; # 7.5min
                on-timeout = "systemctl suspend";
              }
            ];
          };
        };

        services.hyprpaper = {
          enable = true;
          package = pkgs.unstable.hyprpaper;
          settings = {
            ipc = true;
            splash = false;
            wallpaper = [
              {
                monitor = "";
                path = "~/current_wallpaper.jpg";
              }
            ];
          };
        };

        services.hyprsunset = {
          enable = true;
          package = pkgs.unstable.hyprsunset;
        };

        services.hyprpolkitagent = {
          enable = true;
          package = pkgs.unstable.hyprpolkitagent;
        };
      }
    ];

    environment.systemPackages = with pkgs.unstable; [
      foot

      elephant
      app2unit
      hyprshot
      walker
      swaynotificationcenter
      socat # needed to listen to hyprland event socket from bash
      brightnessctl
      playerctl
      bluetui
      pwvucontrol # pipewire control
      overskride # bluetooth control
      grim # grab images from wayland compositor
      slurp # select regions in wayland compositor
      nwg-look # gsettings editor
      adwaita-icon-theme

      loupe # gnome photo viewer
      papers # gnome pdf viewer
      baobab # gnome disk analyzer
      showtime # gnome totem replacement
      vlc
      gnome-font-viewer
      gnome-characters
      gnome-maps
      resources
      mission-center
      decibels
      file-roller
      gnome-calculator
      gnome-text-editor
      # evince
      simple-scan
      nautilus # gnome file manager
      snapshot # gnome camera
      gnome-disk-utility
      gimp3-with-plugins # image editing
      weather
      dconf-editor # GTK settings
      # inputs.nix-alien.packages.${stdenv.hostPlatform.system}.nix-alien
      pkgs.${namespace}.gnome-control-center-patched
      inputs.simplemoji.packages.${stdenv.hostPlatform.system}.default
      termusic
      bottles
      rsgain

      hyprpicker
      rose-pine-cursor
      rose-pine-hyprcursor

      pkgs.${namespace}.hyprpaper-random
    ];

    services.speechd.enable = true;

    # Force DRM connector reprobe on resume from suspend.
    # USB-C DP alt mode disconnects during sleep are not detected by the kernel,
    # leaving stale "connected" state in sysfs and Hyprland rendering to a ghost
    # monitor. The reprobe updates sysfs, and the udevadm trigger fires a uevent
    # so Hyprland's DRM backend picks up the change.
    powerManagement.resumeCommands = ''
      for connector in /sys/class/drm/card*-DP-*/status /sys/class/drm/card*-HDMI-*/status; do
        echo "detect" > "$connector" 2>/dev/null || true
      done
      ${pkgs.systemd}/bin/udevadm trigger --action=change --subsystem-match=drm
    '';
  };
}
