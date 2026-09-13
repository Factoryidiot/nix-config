# ./lib/nixos/nas.nix
{ pkgs
, ...
}: {

  environment.systemPackages = with pkgs; [
    gptfdisk # Provides sgdisk
    smartmontools # Check disk health/SMART data
    pciutils # For lspci troubleshooting
    nfs-utils # If you ever want to mount NFS
    zfs-autobackup # Great for future off-site replication
  ];

  fileSystems."/storage/data" = {
    device = "tank/data";
    fsType = "zfs";
    options = [ "nofail" ]; # Prevent boot hang if pool is missing
  };

  fileSystems."/storage/appdata" = {
    device = "tank/appdata";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "netbios name" = "tahi";
        "security" = "user";
        "server string" = "Tahi NAS";
        "workgroup" = "WORKGROUP";
        # Disable printers
        "disable spoolss" = "yes";
        "load printers" = "no";
        "printcap name" = "/dev/null";
        "printing" = "bsd";
        # Optimisations for local network performance
        "min protocol" = "SMB2";
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
      };
      data = {
        "path" = "/storage/data";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "factory"; # Use your username here
      };
    };
  };

  services.zfs = {
    autoScrub.enable = true; # Weekly health checks
    autoSnapshot = {
      enable = true; # Automatic "Time Machine" style snapshots
      flags = "-k -p --utc";
      monthly = 1;
    };
  };

}
