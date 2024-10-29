{pkgs, ...}: {
  programs.fish = {
    enable = true;
  };

  programs.bash = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    initExtra = ''
      # if running interactively start fish if not already running
      if [[ $(${pkgs.procps}/bin/ps -p $PPID -o "comm=") != "fish" && -z ''${ZSH_EXECUTION_STRING} ]]
      then
        [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec fish $LOGIN_OPTION
      fi
    '';
  };

  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./rosepine.omp.json));
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    # disbale heroku cli telemetry
    DISABLE_TELEMETRY = "true";
    # disable salesforce cli telemetry, faster rest deploys, better coverage calculation
    SF_DISABLE_TELEMETRY = "true";
    SF_ORG_METADATA_REST_DEPLOY = "true";
    SF_IMPROVED_CODE_COVERAGE = "true";
  };

  home.packages = with pkgs; [
    # nix tools
    alejandra
    nh
    devbox
    nil
  ];
}
