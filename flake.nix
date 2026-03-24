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

    # nice little emoji picker
    simplemoji.url = "github:SergioRibera/Simplemoji?ref=v1.2.3";

    # Qt6 theme engine for Hyprland (replaces qt6ct)
    hyprqt6engine = {
      url = "github:hyprwm/hyprqt6engine";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    peek-a-meet = {
      url = "git+https://github.com/sbresin/peek-a-meet.git";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Shared unfree package allowlist
      allowedUnfreePackages = [
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
        "claude-code"
      ];

      # Shared nixpkgs config (allowUnfree + ROCm for Linux)
      mkNixpkgsConfig =
        {
          system ? "x86_64-linux",
          extraConfig ? { },
        }:
        {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) allowedUnfreePackages;
        }
        // nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "-linux" system) {
          rocmSupport = true;
        }
        // extraConfig;

      # Auto-import all NixOS modules from nix/modules/nixos/*/
      nixosModulesList =
        let
          dir = ./nix/modules/nixos;
        in
        map (name: dir + "/${name}") (builtins.attrNames (builtins.readDir dir));

      # Auto-import all home-manager modules from nix/modules/home/*/
      homeModulesList =
        let
          dir = ./nix/modules/home;
        in
        map (name: dir + "/${name}") (builtins.attrNames (builtins.readDir dir));

      # Pre-compute unstable pkgs per system — outside overlay fixed-point.
      # This avoids the expensive `import nixpkgs-unstable` inside the overlay,
      # where it would depend on `prev.config` and get entangled with the
      # fixed-point resolution. Benchmarked at 35% faster eval (77s → 50s).
      unstablePkgs = builtins.listToAttrs (
        map (system: {
          name = system;
          value = import inputs.nixpkgs-unstable {
            inherit system;
            config = mkNixpkgsConfig { inherit system; };
          };
        }) (systems ++ [ "x86_64-darwin" ])
      );

      # Overlay sets — cachyos kernel overlay is only useful on x86_64-linux
      baseOverlays = with self.overlays; [
        unstable
        lix
        sebe-packages
      ];
      x86LinuxOverlays = baseOverlays ++ [ self.overlays.cachyos ];

      overlaysForSystem = system: if system == "x86_64-linux" then x86LinuxOverlays else baseOverlays;

      # Shared NixOS modules applied to ALL hosts
      sharedNixosModules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.impermanence.nixosModules.impermanence
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak

        # nixpkgs config + home-manager settings (overlays set per-host in mkNixos)
        {
          nixpkgs.config = mkNixpkgsConfig { };

          home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
            backupFileExtension = "backuphm";
            extraSpecialArgs = { inherit inputs self; };
            sharedModules = homeModulesList;
          };
        }
      ]
      ++ nixosModulesList;

      # Helper to create a NixOS system configuration
      mkNixos =
        {
          hostPath,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs self; };
          modules =
            sharedNixosModules
            ++ [ { nixpkgs.overlays = overlaysForSystem system; } ]
            ++ extraModules
            ++ [ hostPath ];
        };

      # Helper to create a standalone home-manager configuration
      mkHome =
        {
          system,
          homePath,
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = overlaysForSystem system;
            config = mkNixpkgsConfig { inherit system; };
          };
          extraSpecialArgs = { inherit inputs self; };
          modules = homeModulesList ++ [ homePath ];
        };
    in
    {
      overlays = {
        unstable = import ./nix/overlays/unstable { inherit inputs unstablePkgs; };
        lix = import ./nix/overlays/lix;
        sebe-packages = import ./nix/overlays/sebe-packages { inherit inputs; };
        cachyos = inputs.nix-cachyos-kernel.overlays.pinned;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = overlaysForSystem system;
            config.allowUnfree = true;
          };
        in
        pkgs.sebe
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      nixosConfigurations = {
        blade15 = mkNixos {
          hostPath = ./nix/systems/x86_64-linux/blade15;
          extraModules = [
            { home-manager.users.sebe = import (./nix/homes/x86_64-linux + "/sebe@blade15"); }
          ];
        };

        MONDO-1504 = mkNixos {
          hostPath = ./nix/systems/x86_64-linux/MONDO-1504;
          extraModules = [
            inputs.disko.nixosModules.default
            { home-manager.users.sebe = import (./nix/homes/x86_64-linux + "/sebe@MONDO-1504"); }
          ];
        };

        pi-server = mkNixos {
          hostPath = ./nix/systems/aarch64-linux/pi-server;
          system = "aarch64-linux";
          extraModules = [ inputs.disko.nixosModules.default ];
        };

        pi-installer = mkNixos {
          hostPath = ./nix/systems/aarch64-linux/pi-installer;
          system = "aarch64-linux";
        };
      };

      homeConfigurations = {
        "sebe@blade15" = mkHome {
          system = "x86_64-linux";
          homePath = ./nix/homes/x86_64-linux + "/sebe@blade15";
        };

        "sebe@MONDO-1504" = mkHome {
          system = "x86_64-linux";
          homePath = ./nix/homes/x86_64-linux + "/sebe@MONDO-1504";
        };

        "sbresin@MONDO-0614" = mkHome {
          system = "x86_64-darwin";
          homePath = ./nix/homes/x86_64-darwin + "/sbresin@MONDO-0614";
        };
      };
    };
}
