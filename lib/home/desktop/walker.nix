# lib/home/desktop/walker.nix
{ config
, inputs
, lib
, ...
}: {

  imports = [
    inputs.walker.homeManagerModules.default
  ];

  programs.walker = {
    enable = false;
    runAsService = false;
  };

  xdg.configFile = {
    "elephant/desktopapplications.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/elephant/desktopapplications.toml";
    "elephant/calc.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/elephant/calc.toml";
    "walker/config.toml".source =
      lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/walker/config.toml");
    "walker/themes/default/layout.xml".source =
      lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/walker/themes/default/layout.xml");
    "walker/themes/default/style.css".source =
      lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/walker/themes/default/style.css");
  };

}
