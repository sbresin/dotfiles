{
  description = "sebe nix config";

  nixConfig = {
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    # nixpkgs.url = "github:nixos/nixpkgs/73fa8c1289d22294e2f061de6d3653d338d819ae";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # use Lix fork (faster and community driven)
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # no boilerplate flake structure
    snowfall-lib = {
      url = "github:snowfallorg/lib/v3.0.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # use home-manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
    };

    # manages bind mounts to persistent storage
    impermanence.url = "github:nix-community/impermanence";

    # secureboot for nixOS
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
    };

    # patched kernel
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    hyprland.url = "github:hyprwm/Hyprland";

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
      ];

      systems.hosts.blade15.modules = with inputs; [
        nix-flatpak.nixosModules.nix-flatpak
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
