# ./hosts/ruru/installer.nix
# Headless NixOS installation media configuration for Lenovo ThinkCentre M720q
{ pkgs
, lib
, ...
}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Identify on local network
  networking.hostName = "ruru-installer";

  # Enable mDNS discovery so it resolves as ruru-installer.local
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Pre-authorized SSH key for Rhys from whio
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
  ];

  # Helpful utilities pre-loaded in the installer
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    git
    htop
    pciutils
    tmux
    usbutils
  ];
}
