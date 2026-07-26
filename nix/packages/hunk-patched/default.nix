{ pkgs, ... }:
pkgs.unstable.hunk.overrideAttrs (previousAttrs: {
  patches = (previousAttrs.patches or [ ]) ++ [
    ./apex-extensions.patch
  ];
})
