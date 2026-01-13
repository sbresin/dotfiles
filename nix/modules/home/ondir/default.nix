{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkAfter
    getExe
    ;

  cfg = config.programs.ondir;
in {
  options.programs.ondir = {
    enable = mkEnableOption "ondir, the directory-specific task automation tool";

    package = lib.mkPackageOption pkgs "ondir" {};

    config = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration written to {file}`~/.ondirrc`.

        See the ondir documentation for configuration syntax.
      '';
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable Zsh integration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    programs.zsh.initContent = mkIf cfg.enableZshIntegration (
      mkAfter ''
        eval_ondir() {
          eval "$(${getExe cfg.package} "$OLDPWD" "$PWD")"
        }
        chpwd_functions=( eval_ondir ''${chpwd_functions[@]} )
      ''
    );

    home.file.".ondirrc" = mkIf (cfg.config != "") {
      text = cfg.config;
    };
  };
}
