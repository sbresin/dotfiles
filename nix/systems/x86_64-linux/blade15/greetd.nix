{pkgs, ...}: let
  transparent-cursor = pkgs.fetchFromGitHub {
    owner = "johnodon";
    repo = "Transparent_Cursor_Theme";
    rev = "22cf8e6b6ccbd93a7f0ff36d98a5b454f18bed77";
    sha256 = "sha256-wf5wnSiJsDqcHznbg6rRCZEq/pUneRkqFIJ+mNWb4Go=";
  };
  cage = "${pkgs.unstable.cage}/bin/cage";
  tuigreet = "${pkgs.unstable.tuigreet}/bin/tuigreet";
  foot = "${pkgs.unstable.foot}/bin/foot";
  theme = "text=#e0def4;container=#1f1d2e;border=#6e6a86;title=#9ccfd8;prompt=#ebbcba;input=#eb6f92;time=#ebbcba";
  # kmscon = "${pkgs.kmscon}/bin/kmscon --font-dpi=153 --font-size=18 --no-reset-env --login --";
  foot_conf = pkgs.writeTextFile {
    name = "foot.ini";
    text = ''
      [main]
      shell=${tuigreet} --remember --remember-session --time --window-padding 2 --theme '${theme}'

      font=Dank Mono:size=18, Symbols Nerd Font Mono:size=18, Apple Color Emoji:size=18
      font-bold=Dank Mono:size=18:weight=bold, Symbols Nerd Font Mono:size=18, Apple Color Emoji:size=18

      pad=3x3 center-when-maximized-and-fullscreen

      initial-window-mode=fullscreen

      [colors]
      background=191724
      foreground=e0def4
    '';
  };
in {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${cage} -ds -m last -- ${foot} --config=${foot_conf}";
        # command = "${kmscon} ${tuigreet} --remember --remember-session --time --window-padding 2 --theme '${theme}'";
      };
    };
  };

  systemd.services.greetd.environment = {
    XCURSOR_PATH = transparent-cursor;
    XCURSOR_THEME = "Transparent";
  };
}
