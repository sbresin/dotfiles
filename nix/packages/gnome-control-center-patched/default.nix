{gnome-control-center, ...}:
gnome-control-center.overrideAttrs (previousAttrs: {
  pname = "gnome-control-center-patched";

  patches =
    previousAttrs.patches
    ++ [
      ./any-desktop.patch
      ./less-panels.patch
    ];
})
