{
  config,
  lib,
  pkgs,

  ...
}: let
  cfg = config.sebe.font-config;
in {
  options.sebe.font-config = {
    enable = lib.mkEnableOption "configure font rendering";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs.unstable; [
        adwaita-fonts
        corefonts
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        jetbrains-mono
        iosevka
        inter
        noto-fonts
        geist-font
        tamzen
        pkgs.sebe.dank-mono
        pkgs.sebe.dank-mono-nerd
        pkgs.sebe.apple-emoji-linux
        # TODO: windows fonts
      ];

      fontDir.enable = true;

      fontconfig = {
        enable = true;

        # Fixes pixelation
        antialias = true;

        # Fixes antialiasing blur
        hinting = {
          enable = true;
          style = "full"; # no difference
        };

        subpixel = {
          # Makes it bolder
          rgba = "rgb";
          lcdfilter = "default"; # no difference
        };

        defaultFonts = {
          serif = ["Noto Serif"];
          sansSerif = ["Noto Sans"];
          monospace = ["DankMono Nerd Font Mono" "Symbols Nerd Font"];
          emoji = ["Apple Color Emoji"];
        };
      };
    };
  };
}
