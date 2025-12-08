{
  lib,
  pkgs,
  namespace,
  ...
}: {
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    # ./swapfile.nix
    # ./graphics.nix
    # ./powersaving.nix
    ./flatpak.nix
    # ./backups.nix
  ];

  hardware.enableRedistributableFirmware = true;

  # Use the lanzaboote EFI boot loader.
  boot.loader.efi = {
    efiSysMountPoint = "/boot";
    canTouchEfiVariables = true;
  };

  # lanzaboote replaces systemd-boot
  boot.loader.systemd-boot.enable = lib.mkDefault true;

  # for TPM based LUKS decryption we need systemd
  boot.initrd.systemd.enable = true;

  # Use Linux_cachyos kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos-gcc;
  #   .extend (self: super: {
  #   apfs = super.apfs.overrideAttrs (o: {
  #     version = "0.3.16-6.17";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "linux-apfs";
  #       repo = "linux-apfs-rw";
  #       rev = "v0.3.16";
  #       hash = "sha256-11ypevJwxNKAmJbl2t+nGXq40hjWbLIdltLqSeTVdHc=";
  #     };
  #   });
  # });
  # system.modulesTree = [(lib.getOutput "modules" pkgs.linuxPackages_cachyos-gcc.kernel)];

  # use sched_ext
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--autopilot"];
  };

  # SSD needs TRIM
  services.fstrim.enable = true;

  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    useXkbConfig = true; # use xkb.options for tty.
  };

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$7Sq/gCE9D0uBEAlt$QJJS0FCjeIk0dFyQi7MnZIm7nKZ4wYbubjNmCvFA5JqJa8Mzmgv2gCGY7UXDXSoEJPwBTL9cQNBkwrz2LzquJ.";

  users.groups = {
    storage = {};
    plugdev = {};
  };
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "uinput" "networkmanager" "lp" "scanner" "plugdev" "adbusers" "storage" "dialout"];
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
  };

  # enable adb
  programs.adb.enable = true;

  # my own modules
  ${namespace} = {
    desktop.enable = true;
    desktop-essentials.enable = true;
    font-config.enable = true;
    greeter.enable = true;
    impermanence.enable = true;
    kanata.enable = true;
    private-dns.enable = true;
    secureboot.enable = true;
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs.unstable; [
    nvd
    gcc
    vim
    neovim
    git
    git-crypt
    usbutils
    # os setup/debug
    sbctl
    sbsigntool
    gparted
    exfatprogs
    # Terminal setup
    ghostty
    tmux
    zed-editor
    # inputs.wezterm.packages.${system}.default
    pkgs.${namespace}.wezterm
    # language support
    hunspell
    hunspellDicts.en_US
    hunspellDicts.de_DE
    # media / document tools
    imagemagick
    ffmpeg-full
    pngquant
    ocrmypdf
    # GUI Apps
    easyeffects
    # this flakes packages
    pkgs.${namespace}.oclif
  ];

  # link zsh completions, so they are available globally TODO: same for fish/bash?
  environment.pathsToLink = ["/share/zsh"];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    # TODO: does not work yet
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
