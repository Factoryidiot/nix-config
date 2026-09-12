# ./modules/nixos/base-packages.nix
{ pkgs
, ...
}: {

  nixpkgs.config.allowUnfree = true;

  console.keyMap = "us";

  programs.nano.enable = false;

  environment = {
    systemPackages = with pkgs; [
      clinfo
      curl
      git
      lshw
      pciutils
      usbutils
      vim
      wget
      nixpkgs-fmt
      nmap
      sqlite
      desktop-file-utils
    ];
    variables.EDITOR = "vim";
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

}
