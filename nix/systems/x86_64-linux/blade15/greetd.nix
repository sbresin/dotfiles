{pkgs, ...}: let
  transparent-cursor = pkgs.fetchFromGitHub {
    owner = "johnodon";
    repo = "Transparent_Cursor_Theme";
    rev = "22cf8e6b6ccbd93a7f0ff36d98a5b454f18bed77";
    sha256 = "sha256-wf5wnSiJsDqcHznbg6rRCZEq/pUneRkqFIJ+mNWb4Go=";
  };
  cage = "${pkgs.unstable.cage}/bin/cage";
  tuigreet = "${pkgs.unstable.tuigreet}/bin/tuigreet";
  alacritty = "${pkgs.unstable.alacritty}/bin/alacritty";
  alacritty_options = "--option 'window.decorations=\"None\"' --option 'window.startup_mode=\"Fullscreen\"' --option 'font.size=18' --option 'colors.primary.background=\"#191724\"' --option 'mouse.hide_when_typing=true'";
  theme = "text=#e0def4;container=#1f1d2e;border=#6e6a86;title=#9ccfd8;prompt=#ebbcba;input=#eb6f92;time=#ebbcba";
in {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${cage} -ds -m last -- ${alacritty} ${alacritty_options} --command ${tuigreet} --remember --remember-session --time --window-padding 2 --theme '${theme}'";
      };
    };
  };

  systemd.services.greetd.environment = {
    XCURSOR_PATH = transparent-cursor;
    XCURSOR_THEME = "Transparent";
  };
}
