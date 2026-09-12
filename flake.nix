{
  description = "NIXOS Configuration Flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryan4yin/ragenix";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terminaltexteffects = {
      url = "github:ChrisBuilds/terminaltexteffects/release-0.15.0";
      flake = false;
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    vm-curator = {
      url = "github:mroboff/vm-curator/cdcf2acc2027a4db07e9f65b046d4e3119ee8a08";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{ agenix
    , home-manager
    , hyprland
    , impermanence
    , lanzaboote
    , llm-agents
    , nixpkgs
    , nixpkgs-unstable
    , nixvim
    , self
    , ...
    }:
    let
      system = "x86_64-linux"; # The system type we will use
      pkgs = nixpkgs.legacyPackages.${system};

      specialArgs = {
        inherit agenix hyprland impermanence inputs lanzaboote llm-agents nixpkgs-unstable nixvim self;
      };

      commonModules = [
        agenix.nixosModules.default
        ./lib/nixos/secrets.nix
        home-manager.nixosModules.home-manager
        ({ config, ... }: {
          home-manager = {
            backupFileExtension = "backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = specialArgs // { secrets = config.age.secrets; };
          };
        })
        ({ ... }: {
          nixpkgs.overlays = [ ];
        })
      ];

      mkNixosSystem = { name, username, modules, isServer ? false }:
        let
          hostname = name;
          hostArgs = specialArgs // { inherit hostname username isServer; };
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = hostArgs; # Pass the combined args
          modules = commonModules
            ++ modules
            ++ [
            ({ ... }: {
              nixpkgs.hostPlatform = system;
              nixpkgs.config.allowUnfree = true;
              home-manager.users.${username} = import ./users/${username}/default.nix {
                inherit (hostArgs) isServer;
                inherit (specialArgs) agenix inputs lib; # Explicitly inherit agenix, inputs, and lib from specialArgs
              };
            })
          ];
        };
    in
    {

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          agenix.packages.${system}.default
          pkgs.nixpkgs-fmt
        ];
      };

      nixosConfigurations = {

        kea = mkNixosSystem {
          name = "kea";
          username = "dexter";
          modules = [
            ./hosts/kea/default.nix
            {
              system.stateVersion = "25.11";
            }
          ];
        };

        tahi = mkNixosSystem {
          name = "tahi";
          username = "factory";
          isServer = true;
          modules = [
            ./hosts/tahi/default.nix
            {
              nixpkgs.overlays = [ llm-agents.overlays.shared-nixpkgs ];
              nixpkgs.config.permittedInsecurePackages = [
                "pnpm-9.15.9"
              ];
              system.stateVersion = "25.11";
            }
          ];
        };

        whio = mkNixosSystem {
          name = "whio";
          username = "factory";
          modules = [
            ./hosts/whio/default.nix
            {
              nixpkgs.overlays = [ llm-agents.overlays.shared-nixpkgs ];
              nixpkgs.config.permittedInsecurePackages = [
                "electron-39.8.10"
                "pnpm-9.15.9"
              ];
              system.stateVersion = "25.11";
            }
          ];
        };

      };

      # Standard outputs for convenience
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      packages.${system} = {
        nixos-system-tahi = self.nixosConfigurations.tahi.config.system.build.toplevel;
        nixos-system-kea = self.nixosConfigurations.kea.config.system.build.toplevel;
        nixos-system-whio = self.nixosConfigurations.whio.config.system.build.toplevel;
      };

    };

}
