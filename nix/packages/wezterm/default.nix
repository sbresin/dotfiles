{pkgs, ...}: let
  unstable = pkgs.unstable.callPackage ./package.nix {};
in
  unstable
