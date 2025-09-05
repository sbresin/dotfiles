{
  pkgs,
  inputs,
  namespace,
  ...
}: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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

  services.hypridle = {
    enable = true;
    package = pkgs.unstable.hypridle;
  };

  # bluetooth gui and applet
  services.blueman.enable = true;

  # network gui and applet
  programs.nm-applet.enable = true;

  # TODO: nerdshade, lule,

  environment.systemPackages = with pkgs.unstable; [
    foot

    ashell
    hyprpaper
    hyprsunset
    hyprpolkitagent
    walker
    swaynotificationcenter
    brightnessctl
    playerctl
    bluetui
    pwvucontrol # pipewire control
    overskride # bluetooth control
    grim # grab images from wayland compositor
    slurp # select regions in wayland compositor
    nwg-look # gsettings editor

    loupe # gnome photo viewer
    papers # gnome pdf viewer
    baobab # gnome disk analyzer
    showtime # gnome totem replacement
    vlc
    nautilus # gnome file manager
    snapshot # gnome camera
    gnome-disk-utility
    gimp3-with-plugins # image editing
    weather
    dconf-editor # GTK settings
    inputs.nix-alien.packages.${system}.nix-alien
    pkgs.${namespace}.gnome-control-center-patched

    hyprpicker
    rose-pine-cursor
    rose-pine-hyprcursor

    pkgs.${namespace}.app2unit
    pkgs.${namespace}.hyprpaper-random
  ];

  # MissionCenter flatpak needs to run dynamically linked binary
  programs.nix-ld.enable = true;

  services.flatpak = {
    enable = true;
    packages = [
      "io.missioncenter.MissionCenter"
    ];
  };
}
