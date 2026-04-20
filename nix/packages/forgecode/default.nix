# Packages the forgecode zsh plugin (the `:` prefix system).
# The forge binary itself comes directly from the forgecode flake input.
#
# Patches:
#   0001 — Save & chain the previous ^I (Tab) widget instead of unconditionally
#          overwriting it.  This keeps fzf-tab (and any other Tab-completing
#          plugin) working: forge intercepts `:` and `@` patterns, everything
#          else falls through to the original widget.
{ pkgs, inputs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "forge-zsh-plugin";
  version = "unstable";
  src = inputs.forgecode;

  patches = [ ./0001-fix-chain-tab-widget.patch ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/forge-zsh-plugin
    cp -r shell-plugin/* $out/share/forge-zsh-plugin/
  '';
}
