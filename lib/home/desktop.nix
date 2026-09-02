# ./lib/home/desktop.nix
{ pkgs
, ...
}:
{
  imports = [
    ./desktop/battery-monitor.nix
    ./desktop/browser.nix
    ./desktop/cliamp.nix
    ./desktop/cliphist.nix
    ./desktop/cursor.nix
    ./desktop/hyprland.nix
    ./desktop/quickshell.nix
    ./desktop/swayosd.nix
    ./desktop/terminal.nix
    ./desktop/terminaltexteffects.nix
    ./desktop/vm-curator.nix
  ];

  home.packages = with pkgs; [
    #+----- Audio & Media ------------------------
    ani-cli # Cli tool to browse and play anime
    imv # Powerful Wayland image viewer
    pamixer # Audio control
    playerctl # CMD-Line to control media players
    webp-pixbuf-loader # WebP image support
    wiremix # TUI mixer for PipeWire

    #+----- System Utilities & TUIs --------------
    bluetui # TUI for bluetooth
    gum # Tasty Bubble Gum for your shell
    htop # TUI process viewer
    impala # TUI wifi
    ncdu # Disk usage analyzer with an ncurses interface

    #+----- Other desktop dependencies -----------
    brightnessctl # Brightness control
    libinput # Input device library
    libnotify
    matugen # Material you color generation tool
    swaybg # Basic wallpaper setter for fallback
    wayfreeze # Tool to freeze the screen of a Wayland compositor
    waypaper # GUI wallpaper setter for Wayland-based window managers

    #+----- Security and Auth --------------------
    bitwarden-desktop # Secure and free password manager for all of your devices
    libsecret # Library for storing and retrieving passwords and other secrets

    #+----- Desktop Apps ------------------------
    evince # PDF Viewer
    gnome-calculator # Application that solves mathematical equations and is suitable as a default application in a Desktop environment
    localsend # AirDrop alternative
    zoom-us # zoom.us video conferencing application

    #+----- Screenshots & Screen Recording -------
    grim # Wayland screenshot tool
    slurp # Wayland region selector for grim
    satty # Screenshot annotation tool
    hyprpicker # Wayland color picker
    wl-clipboard # Copy to Wayland clipboard
    #    gpu-screen-recorder			# Screen recording utility

    #+----- Virtualisation -----------------------

    #+----- XDG & Portals ------------------------
    xdg-terminal-exec
    xdg-utils
  ];
}

