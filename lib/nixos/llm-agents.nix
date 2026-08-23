# ./lib/nixos/llm-agents.nix
{ pkgs
, specialArgs ? { }
, ...
}:
let
  inherit (specialArgs) username;
in
{

  environment.systemPackages = with pkgs.llm-agents; [
    antigravity-cli
    openspec # Spec-Driven Development Framework
  ];

  #+----- Impermanence Persistence -------------
  # Modular persistence: persist agent config, credentials, transcripts, and brain data for Antigravity/Gemini and Pi
  environment.persistence."/persistent" = {
    users.${username} = {
      directories = [
        ".gemini"
      ];
    };
  };

}
