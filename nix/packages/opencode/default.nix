{pkgs, ...}:
let
  version = "1.2.22";
  srcHash = "sha256-fSSXUPfvhlWb5YEtW+bbi2mJaOV4Cdx3hbp6lnysxuo=";
  nodeModulesHash = "sha256-U0DRfGsk6SeFqh8DuUsEQ/KmfTokNbr29RSxKgbdqG0=";
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
