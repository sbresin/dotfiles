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
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    # nixpkgs.url = "github:nixos/nixpkgs/f5c96d88c1d87fa801c831abde2113a1217af993";
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
      url = "github:nix-community/home-manager?ref=release-24.11";
    };

    # manages bind mounts to persistent storage
    impermanence.url = "github:nix-community/impermanence";

    # secureboot for nixOS
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
    };

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.4.1";

    };

    };

    # get nightly wezterm
    wezterm.url = "github:wez/wezterm/main?dir=nix";
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

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
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
