{
  lib,
  pkgs,
}: {
  # use standalone home-manager
  programs.home-manager.enable = true;

  # upstream pypi django needs help finding these
  # TODO: should not be necessary when setting DYLD_PATH correctly
  home.sessionVariables = {
    GDAL_LIBRARY_PATH = "${pkgs.gdal}/lib/libgdal.dylib";
    GEOS_LIBRARY_PATH = "${pkgs.geos}/lib/libgeos_c.dylib";
  };

  nix = {
    # https://github.com/NixOS/nixpkgs/issues/337036
    # package = pkgs.lix.overrideAttrs {
    #   doCheck = false;
    #   doInstallCheck = false;
    # };
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
    unar
    # lnav
    bottom
    lazydocker
    oxipng
    rsync
    # stacks + tools
    cargo-nextest
    esbuild
    go
    gopls
    jdt-language-server
    nodejs
    protobuf
    # servers + tools
    # postgresql # TODO: figure out how to use this in macOS
    rabbitmq-server
    valkey
    # macOS tools
    skhd
    terminal-notifier
  ];

  home.stateVersion = "24.05";
}
