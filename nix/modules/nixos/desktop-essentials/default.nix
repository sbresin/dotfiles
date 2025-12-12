{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.desktop-essentials;
in {
  options.${namespace}.desktop-essentials = {
    enable = lib.mkEnableOption "install/setup essentials for desktop systems";
  };

  config = lib.mkIf cfg.enable {
    # needed for cross compiling aarch64 system configs
    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "altgr-weur";
      options = "eurosign:e,caps:escape_shifted_capslock";
    };

    # allow to directly execute Appimages
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    # Enable CUPS to print documents.
    services.printing = {
      enable = true;
      # add hp printer drivers
      drivers = with pkgs; [hplip];
      # enable virtual pdf printer
      cups-pdf.enable = true;
    };
    # Enable Scanner support
    hardware.sane.enable = true;

    # Enable Avahi for IPP network printing
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Enable sound through pipewire
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" ''
            monitor.bluez.properties = {
              bluez5.enable-sbc-xq = true
            }
          '')
        ];
      };
    };

    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          # Enable Bluetooth battery reporting
          Experimental = true;
        };
      };
    };

    # needed by pipewire
    security.rtkit.enable = true;

    services.udev.packages = [
      pkgs.${namespace}.vial-udev-rules
    ];
  };
}
