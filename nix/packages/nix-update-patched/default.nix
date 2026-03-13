{pkgs, ...}:
pkgs.unstable.nix-update.overrideAttrs (prev: {
  patches =
    (prev.patches or [])
    ++ [
      ./lix-eval-compat.patch
    ];
})
