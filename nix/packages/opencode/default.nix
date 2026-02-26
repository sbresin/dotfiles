{pkgs, ...}:
let
  version = "1.2.15";
  srcHash = "sha256-26MV9TbyAF0KFqZtIHPYu6wqJwf0pNPdW/D3gDQEUlQ=";
  nodeModulesHash = "sha256-Diu/C8b5eKUn7MRTFBcN5qgJZTp0szg0ECkgEaQZ87Y=";
in
pkgs.unstable.opencode.overrideAttrs (final: old: {
  inherit version;
  src = old.src.override {
    hash = srcHash;
  };
  node_modules = old.node_modules.overrideAttrs {
    outputHash = nodeModulesHash;
  };
})
