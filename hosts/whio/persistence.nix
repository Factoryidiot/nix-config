{ impermanence
, specialArgs
, ...
}:
let
  # Destructure 'username' from the specialArgs passed from flake.nix
  inherit (specialArgs) username;
in
{

  imports = [
    impermanence.nixosModules.default
  ];

  environment.persistence."/persistent" = {
    hideMounts = true;
    # sets the mount option x-gvfs-hide on all the bind mounts
    directories = [
      "/etc/nix/inputs"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/log" # logs and troubleshooting
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    # the following directories will be passed to /persistent/home/$USER
    users.${username} = {
      directories = [
        ".dotfiles"
        ".nixos"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"

        "Projects"
        "tmp"

        {
          directory = ".gnupg";
          mode = "0700";
        }

        {
          directory = ".ssh";
          mode = "0700";
        }

        # misc
        ".config/gdrive"
        ".config/pulse"
        ".pki"

        # cloud native
        {
          directory = ".aws";
          mode = "0700";
        }

        #+----- Browser --------------------------
        ".config/Bitwarden"
        #".config/google-chrome"
        ".config/chromium"
        #".config/helium"
        #".config/net.imput.helium"
        #".config/BraveSoftware"
        #".config/obsidian"
        ".mozilla"

        #+----- Applications ---------------------
        ".local/share/applications"

        ".local/state"

        # language package managers
        ".npm"

      ];
      files = [
        ".config/zsh/.zsh_history"
      ];
    };
  };

}
