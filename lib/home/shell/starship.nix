# ./lib/home/shell/starship.nix
{ config
, lib
, ...
}: {

  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    configPath = "${config.xdg.configHome}/starship/starship.toml";
    #settings = {
    #  add_newline = false;
    #  format = "$directory$git_branch$git_status$character";
    #  right_format = "$time$cmd_duration";
    #};
  };

  programs.zsh.initContent = lib.mkOrder 1500 ''
    if [[ "$TERM" != "linux" ]]; then
      eval "$(starship init zsh)"
    fi
  '';

  xdg.configFile = {
    "starship/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/starship/starship.toml";
  };

}
