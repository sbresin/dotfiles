{pythonPackages, ...}: let
  inherit (pythonPackages) callPackage;
in {
  xonsh-direnv = callPackage ./xontrib-direnv.nix {};
  xontrib-abbrevs = callPackage ./xontrib-abbrevs.nix {};
  xontrib-argcomplete = callPackage ./xontrib-argcomplete.nix {};
  xontrib-clp = callPackage ./xontrib-clp.nix {};
  xontrib-cmd-durations = callPackage ./xontrib-cmd-durations.nix {};
  xontrib-fzf-completions = callPackage ./xontrib-fzf-completions.nix {};
  xontrib-jedi = callPackage ./xontrib-jedi.nix {};
  xontrib-prompt-bar = callPackage ./xontrib-prompt-bar.nix {};
  xontrib-prompt-starship = callPackage ./xontrib-prompt-starship.nix {};
  xontrib-readable-traceback = callPackage ./xontrib-readable-traceback.nix {};
  xontrib-sh = callPackage ./xontrib-sh.nix {};
  xontrib-term-integrations = callPackage ./xontrib-term-integrations.nix {};
  xontrib-vox = callPackage ./xontrib-vox.nix {};
  xontrib-whole-word-jumping = callPackage ./xontrib-whole-word-jumping.nix {};
}
