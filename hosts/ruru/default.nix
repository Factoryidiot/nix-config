# ./hosts/ruru/default.nix
{ lib
, specialArgs
, ...
}:
let
  inherit (specialArgs) hostname username;
in
{

  imports = [
    #+----- Host specific configuration ----------
    ./hardware-configuration.nix
    ./persistence.nix
    ./kiosk.nix

    #+----- Basic configuration ------------------
    ../../lib/nixos/base-packages.nix
    ../../lib/nixos/base-security.nix
    ../../lib/nixos/btrfs.nix
    ../../lib/nixos/maintenance.nix
    ../../lib/nixos/multimedia.nix
    ../../lib/nixos/zram.nix
  ];

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    kernel.sysctl = {
      "vfs_cache_pressure" = 50;
      "vm.swappiness" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
    };
  };

  # Time and locale are specific to the physical location
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8096 8920 ]; # SSH, Jellyfin client ports
      allowedUDPPorts = [ 1900 7359 ]; # SSDP discovery
    };
    hostName = hostname;
    wireless.iwd.enable = true; # Fast Wi-Fi daemon
  };

  # Trust root certificate from tahi for local secure services
  security.pki.certificateFiles = [
    ../tahi/tahi_root.crt
  ];

  services = {
    avahi.enable = true; # Local network discovery
    resolved.enable = true; # DNS
    udev.enable = true; # Hardware

    # Remote management from whio: Allow root login only with SSH key
    openssh = {
      settings = {
        PermitRootLogin = lib.mkForce "prohibit-password";
      };
    };
  };

  users = {
    users.${username} = {
      home = "/home/${username}";
      isNormalUser = true;
      extraGroups = [
        "audio"
        "input"
        "network"
        "render"
        "users"
        "video"
        username
      ];
      # 15-character random password (Capital, Lower, Numeric, Special)
      initialHashedPassword = "$7$GU..../....mtfaZaPZcI9AyeELe4pvB.$IZx/l1qEIRqxdovDphbrse4D0/HVpLj5BhxxibsfIAA";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
      ];
    };
    users.root = {
      initialHashedPassword = "$7$GU..../....mtfaZaPZcI9AyeELe4pvB.$IZx/l1qEIRqxdovDphbrse4D0/HVpLj5BhxxibsfIAA";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
      ];
    };
  };

}
