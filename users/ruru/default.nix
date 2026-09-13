# ./users/ruru/default.nix
{ inputs
, ...
}:

{
  imports = [
    inputs.nixvim.homeModules.nixvim

    ./core.nix

    ../../lib/home/btop.nix
    ../../lib/home/git.nix
    ../../lib/home/shell.nix
    ../../lib/home/ssh.nix
    ../../lib/home/tmux.nix
    ../../lib/home/nixvim.nix
    ../../lib/home/yazi.nix
  ];
}
