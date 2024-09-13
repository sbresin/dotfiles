{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  home, # The home architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format, # A normalized name for the home target (eg. `home`).
  virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.
  # All other arguments come from the home home.
  config,
  ...
}: {
  # use standalone home-manager
  programs.home-manager.enable = true;

  nix = {
    # https://github.com/NixOS/nixpkgs/issues/337036
    package = pkgs.lix.overrideAttrs {
      doCheck = false;
      doInstallCheck = false;
    };
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  programs.fish = {
    enable = true;
    shellInitLast = ''
      # source ~/.config/fish/config-custom.fish

      # zoxide setup
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # starship setup
      function starship_transient_prompt_func
          ${pkgs.starship}/bin/starship module character
      end
      function starship_transient_rprompt_func
          ${pkgs.starship}/bin/starship module time
      end
      ${pkgs.starship}/bin/starship init fish | source
      enable_transience
    '';
  };

  programs.zsh = {
    enable = true;
    initExtra = ''
      source ~/.profile

      # if running interactively start fish if not already running
      if [[ $(${pkgs.procps}/bin/ps -p $PPID -o "comm=") != "fish" && -z ''${ZSH_EXECUTION_STRING} ]]
      then
        [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec fish $LOGIN_OPTION
      fi
    '';
  };

  home.packages = with pkgs; [
    # nix tools
    alejandra
    nh
    devbox
    # basics
    git
    neovim
    bash
    fish
    docker
    starship
    colima
    # cli tools
    # mise
    gnugrep
    scc
    shellcheck
    delta
    bat
    eza
    fd
    fzf
    glow
    lazygit
    jq
    yq
    sad
    stow
    unar
    ripgrep
    gnused
    zoxide
    sloc
    findutils
    miller
    less
    imagemagick
    pre-commit
    # lnav
    oxipng
    rsync
    bottom
    lazydocker
    # platform tools
    gh
    pkgs.${namespace}.sf-cli
    heroku
    google-cloud-sdk
    act
    fastly
    # stacks + tools
    rustup
    cargo-nextest
    jdt-language-server
    python3
    poetry
    nodejs_latest
    esbuild
    go
    gopls
    # macOS tools
    terminal-notifier
    skhd
  ];

  news.display = "silent";
  news.json = pkgs.lib.mkForce {};
  news.entries = pkgs.lib.mkForce [];

  home.stateVersion = "24.05";
}
