{
  description = "sebe nix config";

  nixConfig = {
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://wezterm.cachix.org"
      "https://hyprland.cachix.org"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # nixpkgs-d3b2661f7.url = "github:nixos/nixpkgs/d3b2661f728ad6d24b1f4b0fa74394a24d6b1dc4";

    # no boilerplate flake structure
    snowfall-lib = {
      url = "github:snowfallorg/lib/v3.0.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # use home-manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
    };

    # manages bind mounts to persistent storage
    impermanence.url = "github:nix-community/impermanence";

    # secureboot for nixOS
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
    };

    # patched kernel
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # declarative disk partitioning
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # run unpatched dynamically linked binaries
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
    };
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
        chaotic.overlays.default
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
        chaotic.nixosModules.nyx-cache
        chaotic.nixosModules.nyx-overlay
        chaotic.nixosModules.nyx-registry
        nix-flatpak.nixosModules.nix-flatpak
      ];

      systems.hosts.MONDO-1504.modules = with inputs; [
        disko.nixosModules.default
      ];

      systems.hosts.pi-server.modules = with inputs; [
        disko.nixosModules.default
      ];

      channels-config = {
        allowUnfreePredicate = pkg: let
          pkgName = inputs.nixpkgs.lib.getName pkg;
        in (builtins.elem pkgName [
          "corefonts"
          "nvidia-x11"
          "nvidia-settings"
          "dank-mono"
          "terraform"
          "ngrok"
          "steam"
          "steam-unwrapped"
          "zsh-abbr"
          "duckstation"
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
