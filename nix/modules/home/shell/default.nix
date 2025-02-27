{
  pkgs,
  namespace,
  ...
}: {
  # ************************************************************************************************
  # SHELLS
  programs.bash = {
    enable = true;
    initExtra =
      # bash
      ''
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
    initExtra =
      # bash
      ''
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
    extensions = with pkgs.unstable; [
      # not using programs.gh-dash.enable, in order to stow config file
      gh-dash
    ];
    settings = {
      # git_protocol = "ssh";
      prompt = "enabled";
    };
  };

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
    package = pkgs.unstable.poetry;
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
    SF_CARAPACE_SPEC_MACROS_FILE = "$HOME/.config/carapace/sf-macros.yaml";
    FZF_DEFAULT_OPTS = ''
      --color=bg+:#1f1d2e,bg:#191724,spinner:#9ccfd8,hl:#c4a7e7
      --color=fg:#908caa,header:#c4a7e7,info:#ebbcba,pointer:#9ccfd8
      --color=marker:#9ccfd8,fg+:#e0def4,prompt:#ebbcba,hl+:#c4a7e7
    '';
  };

  home.packages = with pkgs.unstable; [
    git-crypt
    dig
    # terminal clipboard
    wl-clipboard
    xclip
    xsel
    # nix tools
    nix-your-shell
    alejandra
    nh
    nurl
    devbox
    # languageservers
    nil
    lua-language-server
    luaformatter
    efm-langserver
    marksman
    # stacks
    nodejs
    pnpm
    temurin-bin
    go
    rustup
    python3
    uv
    ruff
    sqruff
    # wasm
    binaryen
    wasm-bindgen-cli
    wasm-tools
    wasm-pack
    twiggy
    # CLI tools
    bkt
    miller
    jq
    stow
    wget
    sad
    glow
    chafa
    pre-commit
    yq
    gh-dash
    # platform tools
    act
    fastly
    google-cloud-sdk
    heroku
    terraform
    # sfdc development
    pkgs.${namespace}.sf-cli
    pkgs.${namespace}.sfp-cli
    # xonsh with xontribs
    (pkgs.${namespace}.xonsh.override
      {pkgs = pkgs.unstable;})
  ];
}
