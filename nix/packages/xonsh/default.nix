{channels, ...}: let
  xontribs = import ./xontribs;
in
  channels.nixpkgs-unstable.xonsh.override {
    python3 = channels.nixpkgs-unstable.python313;
    extraPackages = pythonPackages:
      with xontribs {inherit pythonPackages;}; [
        xonsh-direnv
        xontrib-abbrevs
        xontrib-argcomplete
        xontrib-clp
        xontrib-cmd-durations
        xontrib-fzf-completions
        xontrib-jedi
        xontrib-prompt-bar
        xontrib-prompt-starship
        xontrib-readable-traceback
        xontrib-sh
        xontrib-term-integrations
        xontrib-vox
        xontrib-whole-word-jumping
      ];
  }
