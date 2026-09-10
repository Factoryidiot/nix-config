# ./lib/home/desktop/hyprland.nix
{ config
, ...
}: {

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    systemd.enable = false; # As II used UWSM systemd integration needs to be disabled.
    xwayland.enable = true;
  };

  services.hyprsunset.enable = true;
  services.hypridle.enable = true;

  systemd.user.services.hypridle = {
    Service = {
      Environment = [
        "PATH=${config.home.homeDirectory}/.dotfiles/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };
  };

  # Link the configuration file from your dotfiles directory
  xdg.configFile = {
    #+----- Main Hyprland configuration ----------
    "hypr/hyprland.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/hyprland.lua";

    #+----- Modules ------------------------------
    "hypr/modules/autostart.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/autostart.lua";
    "hypr/modules/keybindings.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/keybindings.lua";

    #+----- applications -------------------------
    "hypr/modules/apps/browsers.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/apps/browsers.lua";
    "hypr/modules/apps/gaming.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/apps/gaming.lua";
    "hypr/modules/apps/system.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/apps/system.lua";

    #+----- keybindings --------------------------
    "hypr/modules/bindings/hardware.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/bindings/hardware.lua";
    "hypr/modules/bindings/launchers.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/bindings/launchers.lua";
    "hypr/modules/bindings/window_mgmt.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/bindings/window_mgmt.lua";
    "hypr/modules/bindings/workspaces.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/bindings/workspaces.lua";

    "hypr/modules/envs.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/envs.lua";
    "hypr/modules/input.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/input.lua";
    "hypr/modules/looknfeel.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/looknfeel.lua";
    "hypr/modules/monitors.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/monitors.lua";
    "hypr/modules/windows.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/modules/windows.lua";

    #+----- Standalone Hypr Daemons (.conf) ------
    "hypr/hypridle.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/hypridle.conf";
    "hypr/hyprlock.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/hyprlock.conf";
    "hypr/hyprsunset.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/hyprsunset.conf";

    #+----- Theme --------------------------------
    "hypr/theme.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hypr/theme.conf";
  };

}
