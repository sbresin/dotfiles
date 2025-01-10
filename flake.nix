{
  description = "sebe nix config";

  nixConfig = {
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://wezterm.cachix.org"
      "https://hyprland.cachix.org"
      "https://anyrun.cachix.org"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    # nixpkgs.url = "github:nixos/nixpkgs/f5c96d88c1d87fa801c831abde2113a1217af993";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # use Lix fork (faster and community driven)
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
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

    # # In order to configure macOS systems.
    # darwin = {
    #   url = "github:lnl7/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # manages bind mounts to persistent storage
    impermanence.url = "github:nix-community/impermanence";

    # secureboot for nixOS
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
    };

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.4.1";

    # anyrun launcher
    anyrun = {
      url = "github:anyrun-org/anyrun";
    };

    # razer hardware settings
    razer-laptop-control = {
      url = "github:Razer-Linux/razer-laptop-control-no-dkms";
      inputs.nixpkgs.follows = "nixpkgs";
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

      overlays = with inputs; [
        # lix-module.overlays.lixFromNixpkgs
        (final: prev: {
          unstable = nixpkgs-unstable.legacyPackages.${prev.system};
          # use this variant if unfree packages are needed:
          # unstable = import nixpkgs-unstable {
          #   inherit system;
          #   config.allowUnfree = true;
          # };#
        })
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
      ];

      systems.hosts.blade15.modules = with inputs; [
        nix-flatpak.nixosModules.nix-flatpak
        razer-laptop-control.nixosModules.default
      ];

      homes.modules = with inputs; [
        anyrun.homeManagerModules.default
      ];

      channels-config = {
        allowUnfreePredicate = pkg:
          builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "nvidia-x11"
            "nvidia-settings"
            "terraform"
          ];
      };

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
