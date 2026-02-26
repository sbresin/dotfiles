{...}: {
  home.username = "sebe";
  home.homeDirectory = "/home/sebe";

  # use bluetooth device buttons for media control
  services.mpris-proxy.enable = true;

  # Tell libddcutil (used by ddcutil-service & vdu_controls) to skip the
  # laptop's internal eDP panel I2C bus. Probing i2c-3 (AMDGPU DM i2c hw
  # bus 0, wired to eDP-1) can deadlock the amdgpu driver and freeze the
  # screen on this Framework AMD Strix Point laptop.
  xdg.configFile."ddcutil/ddcutilrc".text = ''
    [global]
    options: --ignore-bus 3
  '';

  home.stateVersion = "25.11";
}
