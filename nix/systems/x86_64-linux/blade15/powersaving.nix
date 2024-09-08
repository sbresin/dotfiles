{lib, ...}: {
  services.thermald.enable = true;

  services.tlp.enable = true;
  services.tlp.settings = {
    # stay cold on AC as well
    RUNTIME_PM_ON_AC = "auto";
  };
  services.power-profiles-daemon.enable = lib.mkForce false;
}
