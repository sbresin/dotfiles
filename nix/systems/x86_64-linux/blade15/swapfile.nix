{pkgs, ...}: {
  systemd.services = {
    create-swapfile = {
      serviceConfig.Type = "oneshot";
      wantedBy = ["swap-swapfile.swap"];
      script = ''
        swapfile="/swap/swapfile"
        if [[ -f "$swapfile" ]]; then
          echo "Swap file $swapfile already exists, taking no action"
        else
          echo "Setting up swap file $swapfile"
          ${pkgs.btrfs-progs}/bin/btrfs filesystem mkswapfile --size 4g --uuid clear "$swapfile"
        fi
      '';
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 1024 * 4; # 4GiB
    }
  ];
}
