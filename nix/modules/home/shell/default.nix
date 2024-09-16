{...}: {
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

    enableFishIntegration = true;
    enableZshIntegration = true;
  };
}
