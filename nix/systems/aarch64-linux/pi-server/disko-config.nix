{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            FIRMWARE = {
              priority = 1;
              label = "FIRMWARE";
              type = "0700"; # msftdata Microsoft Basic Data
              size = "128M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/firmware";
              };
            };
            ESP = {
              type = "EF00"; # EFI System Partition
              label = "ESP";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              label = "ROOT";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  "@home" = {
                    mountOptions = [ "compress-force=zstd:1" ];
                    mountpoint = "/home";
                  };
                  "@nix" = {
                    mountOptions = [
                      "compress-force=zstd:1"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                  "@persistent" = {
                    mountOptions = [
                      "compress-force=zstd:1"
                      "noatime"
                    ];
                    mountpoint = "/persistent";
                  };

                  "@swap" = {
                    mountpoint = "/.swapvol";
                    mountOptions = [
                      "noatime"
                    ];
                    swap = {
                      swapfile.size = "2G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=2G"
        "defaults"
        "mode=755"
      ];
    };
  };
}
