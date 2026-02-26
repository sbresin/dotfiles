{pkgs, ...}:
pkgs.unstable.zsh-fzf-tab.overrideAttrs (previousAttrs: {
  patches =
    (previousAttrs.patches or [])
    ++ [
      ./0001-fix-no-more-double-escaping.patch
      ./0002-fix-carapace-dir-complete.patch
    ];
})
