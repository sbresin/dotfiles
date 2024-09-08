{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
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
  ];

  nix.package = pkgs.lix;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi = {
    efiSysMountPoint = "/efi";
    canTouchEfiVariables = true;
  };

  # lanzaboote replaces systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  # for TPM based LUKS decryption we need systemd
  boot.initrd.systemd.enable = true;

  environment.persistence."/persistent" = {
    enable = true; # NB: Defaults to true, not needed
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/flatpak"
      "/var/cache/tuigreet"
      "/etc/secureboot"
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

  networking.hostName = lib.mkForce "sebe_laptop";
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
  # services.xserver.enable = true;
  programs.xwayland.enable = true;

  # default to Wayland for chromium/electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.NIX_BUILD_SHELL = "fish";

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = false;
  services.xserver.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverridePackages = [pkgs.mutter];
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling']
    '';
  };

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  hardware.pulseaudio.enable = false;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$7Sq/gCE9D0uBEAlt$QJJS0FCjeIk0dFyQi7MnZIm7nKZ4wYbubjNmCvFA5JqJa8Mzmgv2gCGY7UXDXSoEJPwBTL9cQNBkwrz2LzquJ.";
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sebe = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "uinput" "networkmanager" "openrazer"]; # Enable ‘sudo’ for the user.
    initialHashedPassword = "$6$.7TC31zU0p1OfOH2$b7.CZMpPB.X6YFZMR5akKaEhDTlUPnUJc.gXmv1GqnVV528RuQKvqCp0sRTUk/ZXo.eofNBD9QUup6s9adyXI/";
  };

  programs.nh.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    nvd
    gcc
    vim
    neovim
    sbctl
    sbsigntool
    git
    # runtimes
    nodejs
    python3
    temurin-bin
    go
    rustup
    # Terminal setup
    zoxide
    fish
    starship
    inputs.wezterm.packages.${system}.default
    wl-clipboard
    # CLI tools
    stow
    wget
    ripgrep
    eza
    bat
    fd
    sad
    glow
    delta
    fzf
    lazygit
    gh
    unzip
    unar
    # languageservers
    lua-language-server
    luaformatter
    efm-langserver
    marksman
    # formatters
    alejandra
    # language support
    hunspell
    hunspellDicts.en_US
    hunspellDicts.de_DE
    piper-tts
    # media / document tools
    ffmpeg-full
    pngquant
    ocrmypdf
    # GUI Apps
    gnome-tweaks
    vscodium
    telegram-desktop
    # Emulators
    dolphin-emu
    lime3ds
    cemu
    mgba
    # this flakes packages
    pkgs.${namespace}.razer-cli
    pkgs.${namespace}.apple-emoji-linux
    pkgs.${namespace}.sf-cli
    pkgs.${namespace}.oclif
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono" "NerdFontsSymbolsOnly"];})
    jetbrains-mono
    iosevka
  ];

  fonts.fontDir.enable = true;

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

  hardware.openrazer.enable = true;
  services.razer-laptop-control = {
    enable = true;
    package = pkgs.${namespace}.razer-laptop-control;
  };

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
