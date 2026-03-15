{inputs}: final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config = prev.config;
  };
}
# Use unstable ROCm packages for better gfx1150 (RDNA4) support
// prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  rocmPackages = final.unstable.rocmPackages;
}
