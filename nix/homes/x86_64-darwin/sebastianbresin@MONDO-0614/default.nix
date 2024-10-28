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

  # upstream pypi django needs help finding these
  home.sessionVariables = {
    GDAL_LIBRARY_PATH = "${pkgs.gdal}/lib/libgdal.dylib";
    GEOS_LIBRARY_PATH = "${pkgs.geos}/lib/libgeos_c.dylib";
  };

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

  home.packages = with pkgs; [
    # nix tools
    alejandra
    nh
    devbox
    # basics
    git
    neovim
    docker
    starship
    colima
    # cli tools
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
    protobuf
    terraform
    # servers + tools
    valkey
    postgresql
    rabbitmq-server
    # macOS tools
    terminal-notifier
    skhd
  ];

  home.stateVersion = "24.05";
}
