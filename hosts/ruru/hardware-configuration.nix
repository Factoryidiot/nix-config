# /hosts/ruru/hardware-configuration.nix
{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  btrfsOptions = [ "noatime" "compress=zstd:1" "ssd" "discard=async" ];

  # =========================================================================
  # Set all 3 UUIDs here after formatting (see hosts/ruru/INSTALL.md)
  # =========================================================================
  BOOT_ESP_UUID = "2FA0-6F70"; # /dev/nvme0n1p1 (FAT32 EFI partition)
  NVME_LUKS_UUID = "f3153384-24c2-47fd-937c-23cfae68ff51"; # /dev/nvme0n1p2 (LUKS partition)
  BTRFS_UUID = "ef8e9938-7e76-48a5-a5f2-1bd643ad7150"; # /dev/mapper/crypted (Decrypted BTRFS filesystem)
in
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "tpm_crb" "tpm_tis" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.tmp.cleanOnBoot = true;
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "fat"
    "vfat"
  ];

  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-uuid/${NVME_LUKS_UUID}";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/boot" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BOOT_ESP_UUID}";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/btr_pool" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = [ "subvolid=5" ];
    };

  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "relatime" "mode=755" "size=8G" ];
    };

  fileSystems."/nix" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@nix" ];
    };

  fileSystems."/persistent" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@persistent" ];
      neededForBoot = true;
    };

  fileSystems."/swap" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = [ "noatime" "nodatacow" "subvol=@swap" ];
    };

  fileSystems."/tmp" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@tmp" ];
    };

  swapDevices = [
    {
      device = "/swap/swapfile";
    }
  ];

  networking.useDHCP = lib.mkDefault true;
}
