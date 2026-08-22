# lib/home/desktop/mako.nix
{ config
, ...
}: {

  services.mako = {
    enable = false;
  };

  xdg.configFile = {
    "mako/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/mako/config";
  };

}
