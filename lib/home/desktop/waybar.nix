# lib/home/desktop/waybar.nix
{ config
, lib
, ...
}: {

  programs.waybar = {
    enable = false;
  };

  xdg.configFile = {
    "waybar/config.jsonc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/waybar/config.jsonc";
    "waybar/style.css".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/waybar/style.css";
    "waybar/theme.css".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/waybar/theme.css";

  };

}
