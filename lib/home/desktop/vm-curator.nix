{ config
, lib
, ...
}: {

  options.vm-curator = {
    enable = lib.mkEnableOption "vm-curator QEMU VM Manager configuration";
  };

  config = lib.mkIf config.vm-curator.enable {
    xdg.configFile."vm-curator/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vm-curator/config.toml";
  };

}
