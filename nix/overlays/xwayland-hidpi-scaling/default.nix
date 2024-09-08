{
  channels,
  inputs,
  ...
}: final: prev: {
  mutter = prev.mutter.overrideAttrs (oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/xwayland-scaling.patch?h=mutter-xwayland-scaling";
        hash = "sha256-deoWaseI+CnH0aHUWm6YFoD+PRVsFg3zn3wVy4kIiUE=";
      })
    ];
  });
  gnome-settings-daemon = prev.gnome-settings-daemon.overrideAttrs (oldAttrs: {
    patches =
      oldAttrs.patches
      ++ [
        ./gnome-settings-daemon-mr-353.patch
      ];
  });
}
