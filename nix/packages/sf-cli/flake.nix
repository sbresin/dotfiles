
{
  description = "sf cli package";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        nodeDeps = (pkgs.callPackage ./default.nix {}).nodeDependencies;
        sfcli = pkgs.stdenv.mkDerivation {
          name = "salesforce-cli";
          src = pkgs.fetchFromGitHub {
            owner = "salesforcecli";
            repo = "cli";
            rev = "c273e2b4be85a69ebf600fcd958b404e7cfd993d";
            sha256 = "/h1/WLpYm0OTFYKtBEN9Y0EbjN8rP3EblilnWscA0k8=";
          };
          nativeBuildInputs = [ pkgs.nodejs_20 ]; 
          buildPhase = ''
            # symlink the generated node deps to the current directory for building
            ln -sf ${nodeDeps}/lib/node_modules ./node_modules
            export PATH="${nodeDeps}/bin:$PATH"
            
            yarn; oclif pack
          '';
          # installPhase = "mkdir -p $out/bin; install -t $out/bin foo";
          
          installPhase = "mkdir -p $out/bin;";
        };
      in {
        defaultPackage = sfcli;
      }
    );
}
