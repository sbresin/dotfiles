{...}: {
  services.flatpak = {
    enable = true;
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
    overrides = {
      global = {
        # Force Wayland by default
        Context.sockets = ["wayland" "!x11" "!fallback-x11"];

        Environment = {
          # Fix un-themed cursor in some Wayland apps
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";

          # Force correct theme for some GTK apps
          GTK_THEME = "Adwaita:dark";
        };
      };
      "com.valvesoftware.Steam".Context.sockets = ["x11"]; # No Wayland support
      "org.DolphinEmu.dolphin-emu".Context.sockets = ["x11"]; # No Wayland support
      "org.jdownloader.JDownloader".Context.sockets = ["x11"]; # No Wayland support
      "org.duckstation.DuckStation".Context.sockets = ["x11"]; # No Wayland support
      "org.ryujinx.Ryujinx".Context.sockets = ["x11"]; # No Wayland support
    };
    packages = [
      # tools
      "com.github.tchx84.Flatseal"
      # browsers
      "org.mozilla.firefox"
      "io.github.zen_browser.zen"
      "io.github.ungoogled_software.ungoogled_chromium"
      # emulators
      "net.rpcs3.RPCS3"
      "info.cemu.Cemu"
      "org.duckstation.DuckStation"
      "org.flycast.Flycast"
      # proprietary
      "com.slack.Slack"
      "com.valvesoftware.Steam"
      # sketchy
      "org.jdownloader.JDownloader"
    ];
  };
}
