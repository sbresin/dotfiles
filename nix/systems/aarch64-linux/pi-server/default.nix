{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./disko-config.nix
    ./pi-hole-container.nix
  ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.unstable.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [
      "nvme"
      "usbhid"
      "usb_storage"
    ];
  };
  system.modulesTree = [(lib.getOutput "modules" pkgs.unstable.linuxPackages_rpi4.kernel)];

  boot.kernelParams = [
    "console=ttyS0,115200n8" # uart
    "console=tty0" # last receives kernel logs
    "nomodeset"
  ];

  boot.supportedFilesystems = lib.mkForce ["vfat" "btrfs" "tmpfs"];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "us";
  };

  networking = {
    hostName = "pi-server"; # Define your hostname.
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # To be able to call containers from the host, it is necessary
  # to create a macvlan for the host as well.
  networking.macvlans.mv-enu1u1-host = {
    interface = "enu1u1";
    mode = "bridge";
  };

  systemd.network = {
    enable = true;
    # silly fix for the service failing on nixos rebuild
    # wait-online.enable = lib.mkForce false;
    networks = {
      # don't use the physical interface directly
      "45-enu1u1" = {
        matchConfig.Name = "enu1u1";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          MACVLAN = "mv-enu1u1-host";
          DHCP = "no";
          IPv6AcceptRA = false;
          LinkLocalAddressing = "no";
          MulticastDNS = false;
          LLMNR = false;
        };
      };
      # setup macvlan for the host
      "50-mv-enu1u1-host" = {
        matchConfig.Name = "mv-enu1u1-host";
        linkConfig.RequiredForOnline = "routable";
        networkConfig = {
          BindCarrier = "enu1u1";
          address = [
            "192.168.178.2/24"
          ];
          networkConfig.DHCP = "no";
        };
      };
    };
  };

  services.openssh.enable = true;
  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$7Sq/gCE9D0uBEAlt$QJJS0FCjeIk0dFyQi7MnZIm7nKZ4wYbubjNmCvFA5JqJa8Mzmgv2gCGY7UXDXSoEJPwBTL9cQNBkwrz2LzquJ.";
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIARDUSJe+7l/6PKYcXQyFyoMYeZE7s/zGIbtoXmZfB7y sebe@blade15"
    ];
  };

  environment.systemPackages = [pkgs.neovim];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
