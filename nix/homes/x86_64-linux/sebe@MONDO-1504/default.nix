{...}: {
  home.username = "sebe";
  home.homeDirectory = "/home/sebe";

  # use bluetooth device buttons for media control
  services.mpris-proxy.enable = true;

  home.stateVersion = "25.11";
}
