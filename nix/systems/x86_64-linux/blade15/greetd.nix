{pkgs, ...}: let
  transparent-cursor = pkgs.fetchFromGitHub {
    owner = "johnodon";
    repo = "Transparent_Cursor_Theme";
    rev = "22cf8e6b6ccbd93a7f0ff36d98a5b454f18bed77";
    sha256 = "sha256-wf5wnSiJsDqcHznbg6rRCZEq/pUneRkqFIJ+mNWb4Go=";
  };
  cage = "${pkgs.cage}/bin/cage";
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  alacritty = "${pkgs.alacritty}/bin/alacritty";
  alacritty_options = "--option 'window.decorations=\"None\"' --option 'window.startup_mode=\"Fullscreen\"' --option 'font.size=16' --option 'colors.primary.background=\"#191724\"'";
  theme = "text=#E0DEF4;container=#1f1d2e;border=#6e6a86;title=#9ccfd8;prompt=#ebbcba;input=#eb6f92;time=#ebbcba";
in {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${cage} -dms -- ${alacritty} ${alacritty_options} --command ${tuigreet} --remember --remember-session --time --window-padding 2 --theme '${theme}'";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    Environment = "XCURSOR_PATH=${transparent-cursor}/Transparent";
  };
}
