{
  pkgs,
  options,
  ...
}: {
  # use Lix fork (faster and community driven)
  # nix dependend packages set through overlay
  nix.package = pkgs.lixPackageSets.latest.lix;

  nix.settings = {
    max-jobs = 4; # max derivations built in parallel
    cores = 4; # threads per derivation
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["sebe"];

    # the system-level substituters & trusted-public-keys
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
  };

  # Use nh nix cli wrapper
  programs.nh.enable = true;

  environment.systemPackages = with pkgs.unstable; [
    git
    nix-output-monitor
  ];

  # run dynamically linked binary
  programs.nix-ld = {
    enable = true;
    libraries =
      options.programs.nix-ld.libraries.default
      ++ (
        with pkgs; [
          dbus # libdbus-1.so.3
          fontconfig # libfontconfig.so.1
          freetype # libfreetype.so.6
          glib # libglib-2.0.so.0
          libGL # libGL.so.1
          libxkbcommon # libxkbcommon.so.0
          xorg.libX11 # libX11.so.6
          wayland
        ]
      );
  };
}
