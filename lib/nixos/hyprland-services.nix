# lib/nixos/hyprland-services.nix
{ config
, inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  #pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in
{

  # This makes them available as system daemons managed by NixOS.
  programs.hyprlock = {
    enable = true;
    package = pkgs-unstable.hyprlock;
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;

    package = inputs.hyprland.packages.${system}.default;

  };

  environment.sessionVariables = {
    XDG_SESSION_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1"; # Ensure all graphical programs use Wayland where possible
    XDG_CURRENT_DESKTOP = "Hyprland"; # Set the backend for Hyprland's portal 
    XDG_SESSION_TYPE = "wayland";
  };

  # Install core Hyprland-related packages system-wide
  environment.systemPackages = with pkgs-unstable; [
    hyprpaper
    hyprlock
    hypridle
  ];

}
