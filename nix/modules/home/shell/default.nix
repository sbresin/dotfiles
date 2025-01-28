{
  pkgs,
  lib,
  namespace,
  ...
}: {
  # ************************************************************************************************
  # SHELLS
  programs.bash = {
    enable = true;
    initExtra = ''
      # auto start xonsh after sourcing all the relevant home-manager things
      if [[ $(${pkgs.procps}/bin/ps -p $PPID -o "ucomm=") != "xonsh" && -z ''${BASH_EXECUTION_STRING} && ''${SHLVL} == 1 ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION='''
        exec xonsh $LOGIN_OPTION
      fi
    '';
  };

  programs.fish = {
    enable = true;
    package = pkgs.unstable.fish;
  };

  programs.zsh = {
    enable = true;
    package = pkgs.unstable.zsh;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    initExtra = ''
      # Turn off all beeps
      # unsetopt BEEP
      # Turn off autocomplete beeps
      unsetopt LIST_BEEP

      # auto start xonsh after sourcing all the relevant home-manager things
      if [[ $(${pkgs.procps}/bin/ps -p $PPID -o "ucomm=") != "xonsh" && ''${SHLVL} == 1 ]]
      then
        [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION='''
        exec xonsh $LOGIN_OPTION
      fi
    '';
  };

  #TODO: xonsh config
  xdg.configFile."xonsh/rc.d/01_xonshrc.py".source = ./01_xonshrc.py;
  xdg.configFile."xonsh/starship.toml".source = ./starship_xonsh.toml;

  # ************************************************************************************************
  # PROMPTS

  programs.oh-my-posh = {
    enable = true;
    package = pkgs.unstable.oh-my-posh;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./rosepine.omp.json));
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    package = pkgs.unstable.starship;
  };

  # ************************************************************************************************
  # TOOLS

  programs.bat = {
    enable = true;
    package = pkgs.unstable.bat;
    # extraPackages = with pkgs.unstable.bat-extras; [
    #   batdiff
    #   batgrep
    #   batman
    # ];
  };

  programs.broot.enable = true;

  programs.carapace = {
    enable = true;
    package = pkgs.unstable.carapace;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    package = pkgs.unstable.direnv;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    package = pkgs.unstable.eza;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.fd = {
    enable = true;
    package = pkgs.unstable.fd;
  };

  programs.fzf = {
    enable = true;
    package = pkgs.unstable.fzf;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        # signingkey = "B24A1D10508180D8";
        email = "sebastian.bresin@gmail.com";
        name = "Sebastian Bresin";
      };
      init.defaultBranch = "main";
      # commit.gpgsign = true;
      pull.rebase = false;
      # rebase.autosquash = true;
    };
    delta.enable = true;
    delta.options = {
      line-numbers = true;
      navigate = true;
      dark = true;
      tabs = 2;
      syntax-theme = "rose-pine";
    };
  };

  programs.gh = {
    enable = true;
    package = pkgs.unstable.gh;
    gitCredentialHelper.enable = true;
    settings = {
      # git_protocol = "ssh";
      prompt = "enabled";
    };
  };
  programs.gh-dash.enable = true;

  programs.gpg = {
    enable = true;
    package = pkgs.unstable.gnupg;
  };

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.unstable.pinentry-curses;
    enableBashIntegration = true;
  };

  programs.lazygit = {
    enable = true;
    package = pkgs.unstable.lazygit;
  };

  programs.mise = {
    enable = true;
    package = pkgs.unstable.mise;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.ripgrep = {
    enable = true;
    package = pkgs.unstable.ripgrep;
  };

  programs.zoxide = {
    enable = true;
    package = pkgs.unstable.zoxide;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # ************************************************************************************************
  # STACKS
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };

  # ************************************************************************************************
  # VARS & PACKAGES

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    # disable heroku cli telemetry
    DISABLE_TELEMETRY = "true";
    HEROKU_DISABLE_TELEMETRY = "true";
    # disable salesforce cli telemetry, faster rest deploys, better coverage calculation
    SF_DISABLE_TELEMETRY = "true";
    SF_ORG_METADATA_REST_DEPLOY = "true";
    SF_IMPROVED_CODE_COVERAGE = "true";
    OCLIF_CARAPACE_SPEC_MACROS_FILE = "~/.sf-carapace-macros.yaml";
  };

  home.packages = with pkgs.unstable; [
    git-crypt
    dig
    # terminal clipboard
    wl-clipboard
    xclip
    xsel
    # nix tools
    alejandra
    nh
    devbox
    # languageservers
    nil
    lua-language-server
    luaformatter
    efm-langserver
    marksman
    # stacks
    nodejs
    temurin-bin
    go
    rustup
    python3
    pipx
    # CLI tools
    miller
    jq
    stow
    wget
    sad
    glow
    chafa
    pre-commit
    yq
    # platform tools
    act
    fastly
    google-cloud-sdk
    heroku
    pkgs.terraform #TODO: fix unfree on unstable nixpkgs instance
    # sfdc development
    pkgs.${namespace}.sf-cli
    pkgs.${namespace}.sfp-cli
    # xonsh with xontribs
    (pkgs.${namespace}.xonsh.override
      {pkgs = pkgs.unstable;})
  ];
}
