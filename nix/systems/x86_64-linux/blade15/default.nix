{
  lib,
  pkgs,
  inputs,
  namespace,
  system,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./swapfile.nix
    ./graphics.nix
    ./powersaving.nix
    ./greetd.nix
    ./private-dns.nix
    ./kanata.nix
    ./flatpak.nix
    ./desktop-env.nix
  ];

  # nix.package = pkgs.lix;

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi = {
    efiSysMountPoint = "/efi";
    canTouchEfiVariables = true;
  };

  # lanzaboote replaces systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # for TPM based LUKS decryption we need systemd
  boot.initrd.systemd.enable = true;

  environment.persistence."/persistent" = {
    enable = true; # NB: Defaults to true, not needed
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/flatpak"
      "/var/lib/nixos"
      "/var/lib/sbctl"
      "/var/lib/systemd/backlight"
      "/var/lib/systemd/coredump"
      "/var/cache/tuigreet"
      "/etc/NetworkManager/system-connections"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  # Use Linux_zen kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # use system76 rust scheduler
  services.system76-scheduler.enable = true;

  # SSD needs TRIM
  services.fstrim.enable = true;

  # networking.hostName = lib.mkForce "sebe_laptop";
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    # font = "Lat2-Terminus32";
    keyMap = "us";
    #  useXkbConfig = true; # use xkb.options in tty.
  };

  # Use kmscon
  # services.kmscon = {
  #   enable = true;
  #   fonts = [ { name = "Jetbrains Mono"; package = pkgs.jetbrains-mono; } ];
  #   extraConfig = ''
  #     font-size=14
  #     font-dpi=144
  #   '';
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  programs.xwayland.enable = true;

  # default to Wayland for chromium/electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = false;
  services.xserver.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverridePackages = [pkgs.mutter];
    # TODO: not all are needed post GNOME 47
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling', 'variable-refresh-rate']
    '';
  };

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    # add hp printer drivers
    drivers = with pkgs; [hplip];
    # enable virtual pdf printer
    cups-pdf.enable = true;
  };
  # Enable Scanner support
  hardware.sane.enable = true;

  # Enable Avahi for IPP network printing
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound through pipewire
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" ''
          monitor.bluez.properties = {
            bluez5.enable-sbc-xq = true
          }
        '')
      ];
    };
  };

  # Enable Bluetooth battery reporting
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

  # needed by pipewire
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManagers).
  services.libinput.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$7Sq/gCE9D0uBEAlt$QJJS0FCjeIk0dFyQi7MnZIm7nKZ4wYbubjNmCvFA5JqJa8Mzmgv2gCGY7UXDXSoEJPwBTL9cQNBkwrz2LzquJ.";

  users.groups = {
    storage = {};
    plugdev = {};
  };
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "uinput" "networkmanager" "lp" "scanner" "plugdev" "cdrom" "adbusers" "openrazer" "storage" "gamemode"];
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
  };

  # enable adb
  programs.adb.enable = true;

  # allow to directly execute Appimages
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Use nh nix cli wrapper
  programs.nh.enable = true;

  # enable cd burning (needed for k3b)
  security.wrappers = {
    cdrdao = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrdao}/bin/cdrdao";
    };
    cdrecord = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrtools}/bin/cdrecord";
    };
  };

  # gaming stuff
  modules.gaming.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [
      gnome-tweaks
      gnome-browser-connector
      gnome-network-displays
      kdePackages.k3b
      streamrip
    ]
    ++ (with pkgs.unstable; [
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
      ntfs3g
      # desktop setup
      inputs.anyrun.packages.${system}.anyrun
      # Terminal setup
      inputs.wezterm.packages.${system}.default
      # TODO: get wayland working
      #
      # (inputs.wezterm.packages.${system}.default.overrideAttrs {
      #   patches = [./wezterm-wayland-resize.patch ./wezterm-wayland.patch];
      # })
      # language support
      hunspell
      hunspellDicts.en_US
      hunspellDicts.de_DE
      piper-tts
      # media / document tools
      imagemagick
      tectonic
      ffmpeg-full
      pngquant
      ocrmypdf
      # GUI Apps
      brasero
      dvdplusrwtools
      cdrdao
      cdrtools
      # this flakes packages
      pkgs.${namespace}.razer-cli
      # pkgs.${namespace}.apple-emoji-linux
      pkgs.${namespace}.oclif
      pkgs.${namespace}.bt-dualboot
      pkgs.${namespace}.export-ble-infos
      # pkgs.${namespace}.ryujinx
    ]);

  fonts.packages = with pkgs.unstable; [
    adwaita-fonts
    corefonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    jetbrains-mono
    iosevka
    inter
    noto-fonts
    tamzen
    pkgs.${namespace}.dank-mono
    pkgs.${namespace}.apple-emoji-linux
    # TODO: windows fonts
  ];

  fonts.fontDir.enable = true;
  fonts.enableDefaultPackages = true;
  fonts.fontconfig.hinting.style = "medium";

  fonts.fontconfig.defaultFonts = {
    serif = ["Noto Serif"];
    sansSerif = ["Noto Sans"];
    monospace = ["Dank Mono" "Symbols Nerd Font"];
    emoji = ["Apple Color Emoji"];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # TODO: does not work yet
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      data-root = "/persistent/docker-data";
    };
  };

  hardware.openrazer = {
    enable = true;
    # useless on laptop, leads to no backlight in gdm after suspend
    devicesOffOnScreensaver = false;
  };
  # services.razer-laptop-control = {
  #   enable = true;
  #   package = pkgs.${namespace}.razer-laptop-control;
  # };

  services.speechd.enable = true;

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
  system.stateVersion = "24.05"; # Did you read the comment?
}
