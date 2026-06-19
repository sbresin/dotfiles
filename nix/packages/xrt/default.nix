{ pkgs, ... }:
pkgs.unstable.callPackage ./package.nix {
  xrt-plugin-amdxdna = pkgs.sebe.xrt-plugin-amdxdna;
}
