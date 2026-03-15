{ pkgs, ... }:
let
  version = "1.2.25";
  srcHash = "sha256-gWJUkrskRYAZX29F+p5z5QnxMjD54nId9i/7jbSQV8s=";
  nodeModulesHash = "sha256-byKXLpfvidfKl8PshUsW0grrRYRoVAYYlid0N6/ke2c=";
in
pkgs.unstable.opencode.overrideAttrs (
  final: old: {
    inherit version;
    src = old.src.override {
      hash = srcHash;
    };
    node_modules = old.node_modules.overrideAttrs {
      outputHash = nodeModulesHash;
    };
  }
)
