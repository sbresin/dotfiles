{
  config,
  lib,
  pkgs,

  inputs,
  ...
}:
let
  cfg = config.sebe.desktop;

  hyprctl = "${pkgs.unstable.hyprland}/bin/hyprctl";

  # Post-resume recovery script — called by hypridle's after_sleep_cmd.
  # Uses absolute Nix store paths so it works in hypridle's minimal systemd
  # environment (which lacks bash, brightnessctl, logger, etc. on PATH).
  resume-script = pkgs.writeShellScript "hypr-resume" ''
    log() { ${pkgs.util-linux}/bin/logger -t "hypr-resume" "$*"; }

    log "=== Post-resume recovery starting ==="

    # 1. Prevent hypridle from re-suspending while we recover.
    #    systemd-inhibit forks to background; the inhibit lock lasts 60s.
    ${pkgs.systemd}/bin/systemd-inhibit --what=idle:sleep --who="resume.sh" \
      --why="Post-suspend recovery" --mode=block sleep 60 &
    log "Idle/sleep inhibited for 60s"

    # 2. Force the internal display on unconditionally as a safety net.
    #    monitor_toggle.sh may later disable it (e.g., lid closed + external),
    #    but we always want *something* visible first.
    ${hyprctl} eval "hl.monitor({ output = 'eDP-1', mode = 'preferred', position = 'auto', scale = 'auto' })" 2>/dev/null || true
    log "Internal display force-enabled"

    # 3. Restore brightness (in case brightnessctl saved a dim state)
    ${pkgs.brightnessctl}/bin/brightnessctl -r 2>/dev/null || true

    # 4. Wait for UCSI/MST DP Alt Mode renegotiation on USB-C
    sleep 5

    # 5. Apply proper lid/external monitor logic
    ${pkgs.bash}/bin/bash ~/.config/hypr/scripts/monitor_toggle.sh
    log "monitor_toggle.sh completed"

    log "=== Post-resume recovery finished ==="
  '';
in
{
  options.sebe.desktop = {
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
      withUWSM = true;
      xwayland.enable = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
    };

    # Override the uwsm compositor entry to use start-hyprland
    # The upstream module uses /run/current-system/sw/bin/Hyprland which
    # triggers a warning from Hyprland about not using start-hyprland
    programs.uwsm.waylandCompositors.hyprland = {
      binPath = lib.mkForce "/run/current-system/sw/bin/start-hyprland";
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
    };

    programs.xwayland = {
      enable = true;
      package = pkgs.unstable.xwayland;
    };



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

    # walker application launcher + elephant backend
    systemd.user.services.walker = {
      description = "Walker application launcher";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ pkgs.unstable.elephant ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${pkgs.unstable.walker}/bin/walker --gapplication-service";
      };
    };

    # Wrapper script reads the full user session PATH (set up by UWSM) before
    # starting elephant, so it can find and launch all apps (system, home-manager,
    # flatpak). NixOS's auto-generated PATH in the unit file is too minimal.
    systemd.user.services.elephant = {
      description = "Elephant application launcher backend";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 10;
        ExecStart = toString (
          pkgs.writeShellScript "elephant-wrapper" ''
            eval "$(${pkgs.systemd}/bin/systemctl --user show-environment | ${pkgs.gnugrep}/bin/grep ^PATH=)"
            exec ${pkgs.unstable.elephant}/bin/elephant "$@"
          ''
        );
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
              after_sleep_cmd = "${resume-script}";
              inhibit_sleep = 3; # lock notify mode - wait for hyprlock to signal locked before sleep
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
                on-timeout = "hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"off\"))'";
                on-resume = "brightnessctl -r";
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
      tidal-hifi
      decibels
      file-roller
      gnome-calculator
      gnome-text-editor
      # evince
      simple-scan
      nautilus # gnome file manager
      snapshot # gnome camera
      gnome-disk-utility
      weather
      dconf-editor # GTK settings
      pkgs.sebe.gnome-control-center-patched
      inputs.simplemoji.packages.${stdenv.hostPlatform.system}.default
      termusic
      # Proton launcher for running Windows games outside Steam
      umu-launcher
      rsgain
      inputs.peek-a-meet.packages.${pkgs.stdenv.hostPlatform.system}.default

      hyprpicker
      rose-pine-cursor
      rose-pine-hyprcursor
      inputs.hyprqt6engine.packages.${stdenv.hostPlatform.system}.default

      pkgs.sebe.hyprpaper-random
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
