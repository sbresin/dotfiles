{ pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    package = pkgs.unstable.mesa;

    # 32-bit support for SDL port, Steam, etc.
    enable32Bit = true;
    package32 = pkgs.unstable.pkgsi686Linux.mesa;
  };
}
