{
  lib,
  pkgs,
  namespace,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./swapfile.nix
    ./graphics.nix
    ./flatpak.nix
    ./backups.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi = {
    efiSysMountPoint = "/efi";
    canTouchEfiVariables = true;
  };
  boot.loader.systemd-boot.enable = lib.mkDefault true;

  # Use Linux_zen kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos-gcc.extend (self: super: {
    apfs = super.apfs.overrideAttrs (o: {
      version = "0.3.16-6.17";
      src = pkgs.fetchFromGitHub {
        owner = "linux-apfs";
        repo = "linux-apfs-rw";
        rev = "v0.3.16";
        hash = "sha256-11ypevJwxNKAmJbl2t+nGXq40hjWbLIdltLqSeTVdHc=";
      };
    });
    openrazer = super.openrazer.overrideAttrs (o: {
      version = "3.10.3";
      src = pkgs.fetchFromGitHub {
        owner = "openrazer";
        repo = "openrazer";
        tag = "v3.10.3";
        hash = "sha256-M5g3Rn9WuyudhWQfDooopjexEgGVB0rzfJsPg+dqwn4=";
      };
      # patches =
      #   o.patches or []
      #   ++ [
      #     ./blade15_base_2021_add_fn_toggle.patch
      #   ];
    });
  });
  system.modulesTree = [(lib.getOutput "modules" pkgs.linuxPackages_cachyos-gcc.kernel)];

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
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # open static port for packet (Android quickshare)
  networking.firewall = {
    allowedTCPPorts = [9300];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    useXkbConfig = true; # use xkb.options for tty.
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

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$7Sq/gCE9D0uBEAlt$QJJS0FCjeIk0dFyQi7MnZIm7nKZ4wYbubjNmCvFA5JqJa8Mzmgv2gCGY7UXDXSoEJPwBTL9cQNBkwrz2LzquJ.";

  users.groups = {
    storage = {};
    plugdev = {};
  };
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "uinput" "networkmanager" "lp" "scanner" "plugdev" "cdrom" "adbusers" "openrazer" "storage" "gamemode" "vboxusers" "wireshark" "dialout"];
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
  };

  # enable adb
  programs.adb.enable = true;

  # enable wireshark
  programs.wireshark = {
    enable = true;
    usbmon.enable = true;
  };

  # enable virtualbox
  virtualisation.virtualbox.host = {
    enable = true;
    package = pkgs.unstable.virtualbox;
    # enableKvm = true;
    # addNetworkInterface = false;
  };

  # my own modules
  ${namespace} = {
    cdburning.enable = true;
    desktop.enable = true;
    desktop-essentials.enable = true;
    font-config.enable = true;
    gaming.enable = true;
    greeter.enable = true;
    impermanence.enable = true;
    kanata.enable = true;
    powersaving = {
      enable = true;
      diskDevices = "nvme-NVMe_CA5-8D512_0021044000VT nvme-Samsung_SSD_970_EVO_Plus_2TB_S4J4NM0R801122Z";
    };
    private-dns.enable = true;
    secureboot.enable = true;
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [
      tectonic
    ]
    ++ (with pkgs.unstable; [
      vim
      neovim
      git
      git-crypt
      usbutils
      # os setup/debug
      ntfs3g
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
      packet
      (pkgs.unstable.kicad.override {
        addons = with pkgs.unstable.kicadAddons; [kikit kikit-library];
      })
      pkgs.freecad
      # stuff for tinkering
      rpiboot
      # this flakes packages
      pkgs.${namespace}.razer-cli
      pkgs.${namespace}.oclif
      pkgs.${namespace}.bt-dualboot
      pkgs.${namespace}.export-ble-infos
      # pkgs.${namespace}.ryujinx
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

  # TODO: does not work yet
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  hardware.openrazer = {
    enable = true;
    # useless on laptop, leads to no backlight in dm after suspend
    devicesOffOnScreensaver = false;
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
