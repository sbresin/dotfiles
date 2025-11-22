{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "gpt";
          efiGptPartitionFirst = false;
          partitions = {
            FIRMWARE = {
              priority = 1;
              type = "EF00";
              size = "32M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = null;
              };
              hybrid = {
                mbrPartitionType = "0x0c";
                mbrBootableFlag = false;
              };
            };
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
                subvolumes = {
                  "@home" = {
                    mountOptions = ["compress=zstd" "compress-force=zstd:1"];
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
