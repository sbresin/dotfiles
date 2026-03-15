{ ... }:
{
  home.username = "sebe";
  home.homeDirectory = "/home/sebe";

  # use bluetooth device buttons for media control
  services.mpris-proxy.enable = true;

  # Tell libddcutil (used by ddcutil-service & vdu_controls) to skip the
  # laptop's internal eDP panel. Probing its I2C bus can deadlock the
  # amdgpu driver and freeze the screen on this Framework AMD Strix Point.
  # Format: MFG-MODEL-PRODUCT_CODE (hyphens in model become underscores).
  xdg.configFile."ddcutil/ddcutilrc".text = ''
    [global]
    options: --ignore-mmid BOE-NE135A1M_NY1-3252
  '';

  home.stateVersion = "25.11";
}
