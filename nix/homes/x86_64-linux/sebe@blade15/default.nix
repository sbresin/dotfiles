{...}: {
  home.username = "sebe";
  home.homeDirectory = "/home/sebe";

  # use standalone home-manager
  programs.home-manager.enable = true;

  # set default apps
  # xdg.mimeApps = {
  #   enable = true;
  #
  #   defaultApplications = {
  #     "text/html" = "io.github.zen_browser.zen.desktop";
  #     "x-scheme-handler/http" = "io.github.zen_browser.zen.desktop";
  #     "x-scheme-handler/https" = "io.github.zen_browser.zen.desktop";
  #     "x-scheme-handler/about" = "io.github.zen_browser.zen.desktop";
  #     "x-scheme-handler/unknown" = "io.github.zen_browser.zen.desktop";
  #   };
  # };

  # use bluetooth device buttons for media control
  services.mpris-proxy.enable = true;

  programs.anyrun = {
    enable = true;
    config = {
      plugins = [
        "applications"
        "symbols"
        "translate"
        "websearch"
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
