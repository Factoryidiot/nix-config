# Gemini Code Assistant Guidelines

This document provides a comprehensive overview of the `.nixos` project, its architecture, and development guidelines. The purpose of this file is to maximize the utility of the Gemini CLI for maintaining design consistency and providing accurate feature implementation advice.

## 1. CONTEXT

This project manages NixOS and Home Manager configurations for multiple systems and users in a declarative and reproducible way using Nix Flakes.

### Technology Stack

- **Core:** Nix, NixOS, Nix Flakes
- **System Configuration:**
  - `disko`: For declarative disk partitioning.
  - `impermanence`: For managing persistent state on otherwise ephemeral filesystems.
- **Desktop Environment:**
  - **Window Manager:** Hyprland (Wayland compositor)
  - **Shell:** zsh with powerlevel10k
  - **Desktop Shell & Notifications:** Quickshell (top status bar, application & action launcher menu, native DBus notification daemon)
- **Secrets Management:** `agenix` for declarative secret management.

### Execution Environment

This project is primarily developed and managed on a NixOS system. Consequently, `nix` commands (e.g., `nix build`, `nix flake fmt`) and NixOS-specific tools are directly available in the system PATH.

System rebuilds and switches use standard NixOS tooling with explicit flake host targets:
```bash
cd ~/.nixos
sudo nixos-rebuild switch --flake .#<hostname>  # e.g., .#whio, .#kea, .#tahi
```
Avoid assuming third-party helper wrappers (such as `nh`) are present unless explicitly installed and enabled in the configuration.

## 2. ARCHITECTURE

The project is structured to separate concerns for hosts, users, and reusable modules.

### Key Directory Structures

- **`flake.nix`**: The entry point of the configuration. It defines the flake's inputs (like `nixpkgs`, `home-manager`, etc.) and outputs (the NixOS configurations for each host).

- **`/hosts`**: Contains the main configuration for each machine. Each host has its own directory (e.g., `/hosts/whio/`) with a `default.nix` that defines the system's configuration by importing modules from `/lib` and specifying host-specific settings.
  - `default.nix`: Main NixOS configuration for the host.
  - `disko.nix`: Declarative disk partitioning using `disko`.
  - `hardware-configuration.nix`: Hardware-specific settings.
  - `persistence.nix`: Defines persistent data using `impermanence`.

- **`/users`**: Contains user-specific configurations. The main entry point for each user is `home.nix` (e.g., `/users/factory/default.nix` / `desktop.nix`), which defines the user's Home Manager configuration.

- **`/lib`**: Contains reusable NixOS and Home Manager modules, organized into `nixos` and `home` subdirectories. This is where the bulk of the configuration logic resides.
  - `/lib/nixos/`: Modules for system-level services and packages (e.g., `nvidia.nix`, `secureboot.nix`).
  - `/lib/home/`: Modules for user-level applications and dotfiles (e.g., `git.nix`, `zsh.nix`, `desktop/quickshell.nix`, `desktop/hyprland.nix`).

- **External Dotfiles (`~/.dotfiles`)**: Raw configuration files (dotfiles) for various applications are now managed in a *separate* Git repository, typically cloned to `~/.dotfiles`. These files are linked into the user's home directory by `home-manager` using the `home.file` option. This approach decouples raw dotfiles from the Nix configuration repository (`~/.nixos`), allowing for easier management and sharing of application-specific configurations independently.

- **`/secrets`**: Manages encrypted secrets using `agenix`. `secrets.nix` defines the secrets, and the actual secret files are encrypted and stored in the directory.

- **`/overlays`**: Used to add or modify Nix packages.

### Component Relationships

1.  The `flake.nix` file ties everything together. It builds the NixOS configurations for each host defined in `/hosts`.
2.  Each host configuration in `/hosts` is a NixOS module that imports and configures modules from `/lib/nixos`.
3.  Host configurations also specify which users are on the system, and point to their respective Home Manager configurations in `/users`.
4.  User configurations in `/users` import and configure modules from `/lib/home`.
5.  Many of the modules in `/lib/home` now manage dotfiles by referring to the files in the *external* `~/.dotfiles` directory.

## 3. GUIDELINES

Adherence to these guidelines is crucial for maintaining the quality and consistency of the codebase.

### Nix Language and Formatting

- **Formatting:** All Nix code should be formatted using `nixpkgs-fmt`.
- **Modularity:** When adding new functionality, prefer creating a new module in `/lib`. Each module should be self-contained and expose options to configure its behavior.
- **Packages:**
  - To add a package to the system, add it to the `environment.systemPackages` list in a relevant module in `/lib/nixos`.
  - To add a package to a user's profile, add it to the `home.packages` list in a relevant module in `/lib/home`.

### Adding New Applications and Configurations

1.  **Dotfiles:** Add the new application's configuration file(s) to your *external* `~/.dotfiles` repository. This repository should be kept separate from `~/.nixos`.
2.  **Home Manager Module:** Create a new module in `/lib/home` (or `/lib/home/desktop` for GUI apps) to manage the application.
    - This module should have an `enable` option.
    - When enabled, it should:
      - Add the application's package to `home.packages`.
      - Link the configuration file from the *external* `~/.dotfiles` directory to the correct location in the user's home directory using `home.file`. The path to your dotfiles repo can be referenced dynamically using `${config.home.homeDirectory}/.dotfiles/...`.
3.  **Import Module:** Import the new module into user home configuration.

### Quickshell Development Rules

- **Detached Process Execution:** Always use `Quickshell.execDetached(["zsh", "-c", cmd])` for launching external scripts, TUIs, or applications from QML buttons. Do not use singleton `Process` objects for interactive launchers as they lock UI execution when processes stay active.
- **Native System Tray Menus:** Keep `//@ pragma UseQApplication` at the top of `shell.qml` so Qt initializes in `QApplication` mode. Delegate tray context menus to `modelData.display(window, x, y)` for native platform submenus (e.g., Steam game lists, Bitwarden).
- **Hyprland IPC:** Use standard socket dispatcher strings with `Hyprland.dispatch("workspace <id>")` instead of Lua API wrappers.
- **Qt & GTK Styling:** Ensure `qt.platformTheme.name = "gtk"` and `pkgs.nordic` are configured in Home Manager so native Qt popup menus inherit the system Nord dark palette.

### Secrets Management

- To add a new secret, use the `agenix` CLI to edit the secrets file. Do not commit unencrypted secrets.
- Refer to secrets in your Nix configuration using `config.age.secrets.<secret_name>.path`.

### Git and Committing

-   Follow conventional commit message standards.
-   Ensure that `nixpkgs-fmt` has been run on your changes before committing.