# ./hosts/ruru/kiosk.nix
{ pkgs
, ...
}:
let
  # Kiosk startup session script
  # Note: Jellyfin Media Player (via mpv) requests Wayland idle inhibition
  # (zwp_idle_inhibit_manager_v1) during video playback, preventing swayidle
  # from triggering display sleep while shows/movies are playing.
  kioskSession = pkgs.writeShellScript "kiosk-session" ''
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export NIXOS_OZONE_WL=1

    # Launch Jellyfin Desktop in 10-foot Big Screen TV mode
    exec ${pkgs.jellyfin-media-player}/bin/jellyfin-desktop --tv --fullscreen
  '';
in
{

  # Cage Wayland Kiosk Compositor
  services.cage = {
    enable = true;
    user = "ruru";
    extraArguments = [ "-s" ]; # Enable XWayland support
    program = "${kioskSession}";
  };

  # Hardware Video Acceleration (Intel UHD Graphics 630 / QuickSync Video)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Primary VA-API / QSV driver for Intel Gen 9+ (UHD 630)
      intel-vaapi-driver # Fallback driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  environment.systemPackages = with pkgs; [
    jellyfin-media-player
    libva-utils # includes `vainfo` for checking hardware video acceleration
    pciutils
    swayidle
    wlopm
  ];

}
