# lib/home/desktop.nix
{ pkgs
, ...
}:

{
  imports = [
    ./desktop/battery-monitor.nix
    ./desktop/browser.nix
    ./desktop/cliphist.nix
    ./desktop/cursor.nix
    ./desktop/hyprland.nix
    ./desktop/mako.nix
    ./desktop/swayosd.nix
    ./desktop/terminal.nix
    ./desktop/walker.nix
    ./desktop/waybar.nix
    ./desktop/terminaltexteffects.nix
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
    bitwarden-desktop
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
    libsecret # Library for storing and retrieving passwords and other secrets

    #+----- Desktoos Apps ------------------------
    evince # PDF Viewer
    gnome-calculator
    localsend # AirDrop alternative
    remmina # RDP
    zoom-us # zoom.us video conferencing application

    #+----- Screenshots & Screen Recording -------
    grim # Wayland screenshot tool
    slurp # Wayland region selector for grim
    satty # Screenshot annotation tool
    hyprpicker # Wayland color picker
    wl-clipboard # Copy to Wayland clipboard
    #    gpu-screen-recorder			# Screen recording utility

    #+----- Virtualisation -----------------------
    #quickemu

    #+----- XDG & Portals ------------------------
    xdg-terminal-exec
    xdg-utils
  ];

  terminaltexteffects.enable = true;
}
