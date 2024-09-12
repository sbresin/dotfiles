{
  description = "sebe nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/f5c96d88c1d87fa801c831abde2113a1217af993";

    # use Lix fork (faster and community driven)
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # no boilerplate flake structure
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # use home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # declarative flatpak installs
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.4.1";

    # razer hardware settings
    razer-laptop-control = {
      url = "github:Razer-Linux/razer-laptop-control-no-dkms";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # get nightly wezterm
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
        lix-module.overlays.lixFromNixpkgs
      ];

      systems.modules.nixos = with inputs; [
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
      ];

      systems.hosts.blade15.modules = with inputs; [
        nix-flatpak.nixosModules.nix-flatpak
        razer-laptop-control.nixosModules.default
      ];

      channels-config = {
        allowUnfreePredicate = pkg:
          builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "nvidia-x11"
            "nvidia-settings"
          ];
      };

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
