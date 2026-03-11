{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: {
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    # ./swapfile.nix
    ./graphics.nix
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
  # lanzaboote uses this, 5 is big enough for the framework
  boot.loader.systemd-boot.consoleMode = "5";

  boot.plymouth.enable = true;

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "4G";
  };

  # for TPM based LUKS decryption we need systemd
  boot.initrd.systemd.enable = true;

  # CachyOS kernel with BORE scheduler, x86-64-v4 optimized for Zen 5
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v4;
  boot.extraModulePackages = [];

  # use sched_ext
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--autopilot"];
  };

  # Custom fan control for Framework laptop - quieter fan curves
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
    };
  };

  # SSD needs TRIM
  services.fstrim.enable = true;

  # Firmware updates via fwupd (BIOS, EC, PD controllers, etc.)
  services.fwupd = {
    enable = true;
    package = pkgs.unstable.fwupd;
  };

  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
  };

  hardware.amdgpu = {
    opencl.enable = true; # enable rocm
    initrd.enable = true; # early KMS
  };

  # DDC/CI monitor control via D-Bus (brightness, contrast for external monitors).
  # Enables hardware.i2c, registers ddcutil-service on D-Bus for auto-start,
  # and provides ddcutil CLI as a dependency.
  services.ddccontrol = {
    enable = true;
    package = pkgs.unstable.ddcutil-service;
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
    shell = pkgs.zsh;
    extraGroups = [
      "adbusers"
      "dialout"
      "docker"
      "input"
      "lp"
      "networkmanager"
      "plugdev"
      "scanner"
      "storage"
      "uinput"
      "wheel"
      config.hardware.i2c.group
    ];
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
  };

  programs.zsh.enable = true;

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
    powersaving = {
      enable = true;
      diskDevices = "nvme-WD_BLACK_SN7100_1TB_25235H806572";
    };
    private-dns.enable = true;
    secureboot.enable = true;
    ollama = {
      enable = true;
      backend = "rocm";
      rocmOverrideGfx = "11.5.1"; # AMD Radeon 890M (gfx1150)
    };
    caddy = {
      enable = true;
      services.ollama.port = 11434;
    };
    docker.enable = true;
  };

  programs._1password = {
    enable = true;
    package = pkgs.unstable._1password-cli;
  };

  programs._1password-gui = {
    enable = true;
    package = pkgs.unstable._1password-gui;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = ["sebe"];
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.${namespace}.neovim-patched
  ] ++ (with pkgs.unstable; [
    vim
    git
    git-crypt
    # os setup/debug
    fwupd
    usbutils
    lm_sensors
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
    vial
    vdu_controls
    # this flakes packages
    pkgs.${namespace}.oclif
    # ROCm tools for GPU monitoring
    pkgs.rocmPackages.rocm-smi
    pkgs.rocmPackages.rocminfo
  ]);

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
