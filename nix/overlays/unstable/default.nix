# The actual `import nixpkgs-unstable` is pre-computed in flake.nix (unstablePkgs)
# and passed in here to avoid entangling it with the overlay fixed-point.
{ inputs, unstablePkgs }:
final: prev:
let
  unstable = unstablePkgs.${prev.stdenv.hostPlatform.system};
in
{
  inherit unstable;
}
# Use unstable ROCm packages for better gfx1150 (RDNA4) support
// prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  rocmPackages = unstable.rocmPackages;
}
