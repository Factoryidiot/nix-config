# lib/home/desktop/terminal.nix
{ config
, pkgs
, ...
}: {

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    installBatSyntax = true;
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile = {
    "alacritty/alacritty.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/alacritty/alacritty.toml";
    "alacritty/screensaver.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/alacritty/screensaver.toml";
    "alacritty/theme.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/alacritty/theme.toml";
    "ghostty/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty/config";
    "ghostty/screensaver".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty/screensaver";
  };

}
