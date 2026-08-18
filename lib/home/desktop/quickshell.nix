# lib/home/desktop/quickshell.nix
{ config
, pkgs
, inputs
, ...
}:
let
  quickshellPkg =
    if inputs ? quickshell && inputs.quickshell ? packages && inputs.quickshell.packages ? ${pkgs.stdenv.hostPlatform.system}
    then inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.quickshell;
in
{
  programs.quickshell = {
    enable = true;
    package = quickshellPkg;
  };

  # Link configuration files from the external dotfiles repository
  xdg.configFile = {
    "quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/quickshell";
  };
}
