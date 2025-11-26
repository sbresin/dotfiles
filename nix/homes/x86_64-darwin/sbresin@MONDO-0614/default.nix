{pkgs, ...}: {
  # use standalone home-manager
  programs.home-manager.enable = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      max-jobs = 8;
    };
  };

  home.packages = with pkgs.unstable; [
    # basics
    kanata
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
    terminal-notifier
  ];

  home.stateVersion = "24.05";
}
