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
    "ghostty/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty/config";
    "ghostty/screensaver".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty/screensaver";
  };

}
