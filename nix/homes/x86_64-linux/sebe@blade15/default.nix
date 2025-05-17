{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  home, # The home architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format, # A normalized name for the home target (eg. `home`).
  virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.
  # All other arguments come from the home home.
  config,
  ...
}: {
  home.username = "sebe";
  home.homeDirectory = "/home/sebe";

  # use standalone home-manager
  programs.home-manager.enable = true;

  # set default apps
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "io.github.zen_browser.zen.desktop";
      "x-scheme-handler/http" = "io.github.zen_browser.zen.desktop";
      "x-scheme-handler/https" = "io.github.zen_browser.zen.desktop";
      "x-scheme-handler/about" = "io.github.zen_browser.zen.desktop";
      "x-scheme-handler/unknown" = "io.github.zen_browser.zen.desktop";
    };
  };
  # use bluetooth device buttons for media control
  services.mpris-proxy.enable = true;

  programs.anyrun = {
    enable = true;
    config = {
      plugins = [
        inputs.anyrun.packages.${pkgs.system}.applications
        inputs.anyrun.packages.${pkgs.system}.symbols
        inputs.anyrun.packages.${pkgs.system}.translate
        inputs.anyrun.packages.${pkgs.system}.websearch
      ];
      x = {fraction = 0.5;};
      y = {fraction = 0.3;};
      width = {fraction = 0.3;};
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;
    };
    extraCss = ''
      .some_class {
        background: red;
      }
    '';

    extraConfigFiles."some-plugin.ron".text = ''
      Config(
        // for any other plugin
        // this file will be put in ~/.config/anyrun/some-plugin.ron
        // refer to docs of xdg.configFile for available options
      )
    '';
  };

  home.stateVersion = "24.05";
}
