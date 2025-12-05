{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "100%";
              label = "NIXOS";
              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key"; # interactive password entry
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Override existing partition
                  subvolumes = {
                    "@home" = {
                      mountOptions = ["compress-force=zstd:1"];
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
                        swapfile.size = "16G";
                      };
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
