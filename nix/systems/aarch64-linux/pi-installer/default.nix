{
  lib,
  pkgs,
  inputs,
  modulesPath,
  system,
  ...
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxKernel.packages.linux_rpi3;
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
    ];
  };

  # fix the following error :
  # modprobe: FATAL: Module ahci not found in directory
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];

  # The last console argument in the list that linux can find at boot will receive kernel logs.
  # The serial ports listed here are:
  # - ttyS0: serial
  # - tty0: hdmi
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
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

  environment.systemPackages = [pkgs.neovim pkgs.disko pkgs.ethtool];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "aarch64-linux";
}
