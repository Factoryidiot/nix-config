# ./hosts/ruru/disko.nix
{

  fileSystems."/persistent".neededForBoot = true;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Default to primary NVMe SSD (change to /dev/sda if using a 2.5" SATA SSD)
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              start = "1MiB";
              end = "500MiB";
              priority = 1;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  fallbackToPassword = true;
                  allowDiscards = true;
                };
                initrdUnlock = false;
                extraFormatArgs = [
                  "--type luks2"
                  "--cipher aes-xts-plain64"
                  "--hash sha512"
                  "--iter-time 5000"
                  "--key-size 256"
                  "--pbkdf argon2id"
                  "--use-random"
                  "--verify-passphrase"
                ];
                extraOpenArgs = [
                  "--timeout 10"
                ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/" = {
                      mountOptions = [ "subvolid=5" ];
                      mountpoint = "/btr_pool";
                    };
                    "@nix" = {
                      mountOptions = [ "compress-force=zstd:1" "noatime" ];
                      mountpoint = "/nix";
                    };
                    "@persistent" = {
                      mountOptions = [ "compress-force=zstd:1" ];
                      mountpoint = "/persistent";
                    };
                    "@swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "16G";
                    };
                    "@tmp" = {
                      mountOptions = [ "compress-force=zstd:1" ];
                      mountpoint = "/tmp";
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

}
