{
  description = "nix config for sebe";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... } @ inputs:
    let
      mkHomeConfig = machineModule: system: home-manager.lib.homeManagerConfiguration {
      # pkgs = nixpkgs.legacyPackages.${system};
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
      };
      modules = [
          # ./sharedConfig
          ./nix/no-news.nix
          machineModule
        ];

        extraSpecialArgs = {
          inherit inputs system;
        };
      };
    in {
      homeConfigurations."sebe@arch-laptop" = mkHomeConfig ./nix/machines/arch.nix "x86_64-linux";
      homeConfigurations."sebe@macbook-work" = mkHomeConfig ./nix/machines/work.nix "x86_64-darwin";
    };
}
