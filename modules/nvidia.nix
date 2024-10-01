{
  config,
  lib,
  nixos-hardware,
  pkgs,
  ...
}:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {

  imports = [
#    nixos-hardware.nixosModules.common-gpu-nvidia

    # TODO: why do I get the below error?
    # error: The option `hardware.intelgpu.loadInInitrd' in `/nix/store/4mgg9mrh8g0qj4g3z9zvqhrniig10bsn-source/systems/evo/hardware/gpus.nix' is already declared in `/nix/store/75hvhrfigcnckibdlg877157bpwjmy85-source/common/gpu/intel'.
    # Where is the other coming from?g
    # inputs.nixos-hardware.nixosModules.common-gpu-intel
  ];
 
  boot = {
    kernelParams = [
      "nvidia-drm.fbdev=1"
      # "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    # initrd.kernelModules = [
    #  "nvidia"
    #  "nvidia_drm"
    #  "nvidia_modeset"
    #  "i2c_nvidia_gpu"
    # ];
  };
 
  hardware = {

    graphics = {
      enable = true;
      # driSupport32Bit = true;
      extraPackages = with pkgs; [ amdvlk ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
      enable32Bit = true; # needed by nvidia-docker
    };

    nvidia = {
      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
      # package = config.boot.kernelPackages.nvidiaPackages.stable;
      # required by most wayland compositors!
      modesetting.enable = true;

      # Enable the Nvidia settings menu,
	    # accessible via `nvidia-settings`.
      nvidiaSettings = true;
 
      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      #package = config.boot.kernelPackages.nvidiaPackages.stable;
      package = config.boot.kernelPackages.nvidiaPackages.beta;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        # Make sure to use the correct Bus ID values for your system!
        amdgpuBusId = "PCI:65:0:0";
        nvidiaBusId = "PCI:01:0:0";
 
        offload = {
          enable = true;
          enableOffloadCmd =  true; # command: nvidia-offload 
        };
        reverseSync.enable = true;
      };

   };

  };

  # for Nvidia GPU
  services.xserver.videoDrivers = [ "nvidia" ]; # will install nvidia-vaapi-driver by default

}
