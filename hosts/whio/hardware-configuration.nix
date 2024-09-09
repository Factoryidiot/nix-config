{ 
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "sd_mod" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.tmp.cleanOnBoot = true; # clear /tmp on boot to get a stateless /tmp directory
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-uuid/65c23503-6f3d-4a28-84d9-73e8bb817770";
  boot.initrd.luks.devices."crypted".allowDiscards = true;
  boot.initrd.luks.devices."crypted".bypassWorkqueues = true;

  fileSystems."/boot" = lib.mkDefault
    { device = "/dev/disk/by-uuid/48E5-EB7B";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/btr_pool" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs"; 
      options = [ "subvolid=5" ];
    };

  fileSystems."/" =
    { device = "tmpfs";
      fsType = "tmpfs";
      options = [ "relatime" "mode=755" ];
    };

  fileSystems."/gnu" = lib.mkDefault
    { device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [ "subvol=@guix" "noatime" "compress-force=zstd:1" ];
    };

  fileSystems."/nix" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "compress-force=zstd:1" ];
    };

  fileSystems."/persistent" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs";
      options = [ "subvol=@persistent" "compress-force=zstd:1" ];
      neededForBoot = true;
    };

  fileSystems."/snapshots" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" "compress-force=zstd:1" ];
    };

  fileSystems."/swap" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs";
      options = [ "subvol=@swap" "ro" ];
    };

  fileSystems."/swap/swapfile" =
    { device = "/swap/swapfile";
      depends = [ "/swap" ];
      fsType = "none";
      options = [ "bind" "rw" ];
    };

  fileSystems."/tmp" = lib.mkDefault
    { device = "/dev/disk/by-uuid/ae315978-8578-4e22-8860-edd70b4d439b";
      fsType = "btrfs";
      options = [ "subvol=@tmp" "compress-force=zstd:1" ];
    };

  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
