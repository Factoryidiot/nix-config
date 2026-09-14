# ./hosts/tahi/persistence.nix
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
      "/var/lib/nixos"
      "/var/log" # logs and troubleshooting
      "/var/lib/prometheus2"
      "/var/lib/grafana"
      "/var/lib/homepage"
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
        "Projects"

        # .config
        ".config/git"

        {
          directory = ".ssh";
          mode = "0700";
        }
      ];

      files = [
        # Any user specific files that need persistence can be added here
      ];
    };
  };

}
