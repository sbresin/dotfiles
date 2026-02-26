{pkgs, ...}: let
  neovim-patched-unwrapped = pkgs.unstable.neovim-unwrapped.overrideAttrs (previousAttrs: {
    patches =
      (previousAttrs.patches or [])
      ++ [
        ./0001-feat-add-leadingspacewidth-buffer-option-lsw.patch
        ./0002-feat-add-leadingspacewidth-auto-computation-plugin.patch
      ];
  });
in
  pkgs.unstable.wrapNeovim neovim-patched-unwrapped {}
