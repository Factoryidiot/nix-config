# ./lib/home/desktop/clicamp.nix
{ config
, pkgs
, ...
}: {

  home.packages = with pkgs; [
    cliamp
    ffmpeg
    yt-dlp
  ];

  xdg.configFile."cliamp/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/cliamp/config.toml";

}
