{
  lib,
  pkgs,
  ...
}: {
  # The last console argument in the list that linux can find at boot will receive kernel logs.
  # The serial ports listed here are:
  # - ttyS0: serial
  # - tty0: hdmi
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
    "nomodeset" # not needed for headless installers
  ];

  boot.supportedFilesystems = lib.mkForce ["vfat" "btrfs" "tmpfs"];

  networking.hostName = "pi-installer";

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIARDUSJe+7l/6PKYcXQyFyoMYeZE7s/zGIbtoXmZfB7y sebe@blade15"
    ];
  };

  environment.systemPackages = with pkgs; [git neovim disko ethtool];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "aarch64-linux";
}
