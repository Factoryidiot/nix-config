# ./hosts/ruru/persistence.nix
{ impermanence
, specialArgs
, ...
}:
let
  inherit (specialArgs) username;
in
{

  imports = [
    impermanence.nixosModules.default
  ];

  environment.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      "/etc/nix/inputs"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/log"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.${username} = {
      directories = [
        ".dotfiles"
        ".nixos"

        {
          directory = ".ssh";
          mode = "0700";
        }

        # Media Player state and preferences
        ".local/share/jellyfinmediaplayer"
        ".config/jellyfinmediaplayer"

        # Audio and system state
        ".config/pulse"
        ".local/state"
      ];
      files = [
        ".config/zsh/.zsh_history"
      ];
    };
  };

}
