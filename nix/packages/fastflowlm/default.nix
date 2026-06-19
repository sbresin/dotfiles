{ pkgs, ... }:
pkgs.unstable.callPackage ./package.nix {
  xrt = pkgs.sebe.xrt;
  xrt-plugin-amdxdna = pkgs.sebe.xrt-plugin-amdxdna;
}
