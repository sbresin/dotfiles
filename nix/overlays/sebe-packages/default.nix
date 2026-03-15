# Overlay that registers all custom packages under pkgs.sebe.*
# Replaces Snowfall Lib's auto-discovery of nix/packages/*/
{ inputs }:
final: prev:
let
  # Standard callPackage — for packages with explicit deps like {lib, stdenv, ...}:
  pkg = path: final.callPackage path { };

  # For packages using the {pkgs, ...}: convention that need the full package set
  pkgFull = path: final.callPackage path { pkgs = final; };
in
{
  sebe = {
    aarch64-installer-netboot = final.callPackage ../../packages/aarch64-installer-netboot {
      pkgs = final;
      inherit inputs;
    };
    apple-emoji-linux = pkg ../../packages/apple-emoji-linux;
    bt-dualboot = pkg ../../packages/bt-dualboot;
    chrome-devtools-mcp = pkgFull ../../packages/chrome-devtools-mcp;
    dank-mono = pkg ../../packages/dank-mono;
    dank-mono-nerd = pkg ../../packages/dank-mono-nerd;
    docs-mcp-server = pkgFull ../../packages/docs-mcp-server;
    es-de = pkg ../../packages/es-de;
    export-ble-infos = pkg ../../packages/export-ble-infos;
    friidump = pkg ../../packages/friidump;
    gnome-control-center-patched = pkg ../../packages/gnome-control-center-patched;
    hyprpaper-random = pkg ../../packages/hyprpaper-random;
    joycond = pkg ../../packages/joycond;
    neovim-patched = pkgFull ../../packages/neovim-patched;
    nix-update-patched = pkgFull ../../packages/nix-update-patched;
    oclif = pkg ../../packages/oclif;
    opencode = pkgFull ../../packages/opencode;
    razer-cli = pkg ../../packages/razer-cli;
    rpi4-uefi-firmware = pkg ../../packages/rpi4-uefi-firmware;
    rusty-psn = pkg ../../packages/rusty-psn;
    sf-cli = pkg ../../packages/sf-cli;
    sfp-cli = pkg ../../packages/sfp-cli;
    threedstool = pkg ../../packages/threedstool;
    vial-udev-rules = pkg ../../packages/vial-udev-rules;
    wezterm = pkgFull ../../packages/wezterm;
    xonsh = pkgFull ../../packages/xonsh;
    zsh-fzf-tab-patched = pkgFull ../../packages/zsh-fzf-tab-patched;
  };
}
