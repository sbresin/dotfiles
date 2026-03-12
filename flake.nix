{
  description = "sebe nix config";

  nixConfig = {
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # nixpkgs-d3b2661f7.url = "github:nixos/nixpkgs/d3b2661f728ad6d24b1f4b0fa74394a24d6b1dc4";

    # no boilerplate flake structure
    snowfall-lib = {
      url = "github:snowfallorg/lib/c566ad8b7352c30ec3763435de7c8f1c46ebb357";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # use home-manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # manages bind mounts to persistent storage
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # secureboot for nixOS
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";

    # CachyOS kernel (BORE scheduler, cachyos perf patches, sched-ext)
    # replaces chaotic-cx/nyx which was archived Dec 2025
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    # do NOT override nixpkgs — patches must match the kernel version pinned upstream

    # declarative disk partitioning
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # run unpatched dynamically linked binaries
    nix-alien.url = "github:thiagokokada/nix-alien";

    # nice little emoji picker
    simplemoji.url = "github:SergioRibera/Simplemoji?ref=v1.2.3";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        root = ./nix;
        namespace = "sebe";

        meta = {
          name = "sebe-flake";
          title = "Sebes Flake";
        };
      };

      overlays = with inputs; [
        nix-cachyos-kernel.overlays.pinned
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
        nix-flatpak.nixosModules.nix-flatpak
      ];

      systems.hosts.MONDO-1504.modules = with inputs; [
        disko.nixosModules.default
      ];

      systems.hosts.pi-server.modules = with inputs; [
        disko.nixosModules.default
      ];

      channels-config = {
        rocmSupport = true; # Enable ROCm GPU support for AMD GPUs
        allowUnfreePredicate = pkg: let
          pkgName = inputs.nixpkgs.lib.getName pkg;
        in (builtins.elem pkgName [
          "corefonts"
          "nvidia-x11"
          "nvidia-settings"
          "dank-mono"
          "dank-mono-nerd"
          "terraform"
          "ngrok"
          "steam"
          "steam-unwrapped"
          "zsh-abbr"
          "duckstation"
          "1password"
          "1password-cli"
          "1password-gui"
          "crush"
          # nvtop dependencies
          #   "libnpp"
        ]);
        # || (inputs.nixpkgs.lib.strings.hasPrefix "cuda" pkgName)
        # || (inputs.nixpkgs.lib.strings.hasPrefix "libcu" pkgName)
        # || (inputs.nixpkgs.lib.strings.hasPrefix "libnv" pkgName);
      };

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
