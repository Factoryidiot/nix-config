# lib/home/gtk.nix
{ pkgs
, ...
}: {

  gtk = {
    enable = true;

    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };

    iconTheme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  home.packages = with pkgs; [
    papirus-icon-theme # Provides fallback icons for Nordic (Nordic-darker inherits Papirus-Dark)
  ];

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "nordic";
      package = pkgs.nordic;
    };
  };

}
