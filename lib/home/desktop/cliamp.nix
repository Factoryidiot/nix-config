{ config
, lib
, pkgs
, ...
}: {

  options.cliamp = {
    enable = lib.mkEnableOption "cliamp music player configuration";
  };

  config = lib.mkIf config.cliamp.enable {
    home.packages = with pkgs; [
      cliamp
    ];

    xdg.configFile."cliamp/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/cliamp/config.toml";
  };

}
