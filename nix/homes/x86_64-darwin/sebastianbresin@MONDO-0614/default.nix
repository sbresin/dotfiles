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
    settings = {
      experimental-features = ["nix-command" "flakes"];
      max-jobs = 8;
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

  home.packages = with pkgs.unstable; [
    # basics
    colima
    docker
    # git
    neovim
    # cli tools
    findutils
    gnugrep
    gnused
    imagemagick
    less
    scc
    shellcheck
    sloc
    # lnav
    bottom
    lazydocker
    oxipng
    rsync
    # stacks + tools
    cargo-nextest
    esbuild
    gopls
    jdt-language-server
    # servers + tools
    # postgresql # TODO: figure out how to use this in macOS
    rabbitmq-server
    valkey
    # macOS tools
    yabai
    skhd
    jankyborders
    terminal-notifier
  ];

  home.stateVersion = "24.05";
}
