# ./lib/home/desktop/vm-curator.nix
{ config
, ...
}: {

  xdg.configFile."vm-curator/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vm-curator/config.toml";

}
