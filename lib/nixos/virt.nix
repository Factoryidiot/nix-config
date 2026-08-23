{ inputs
, pkgs
, username
, ...
}: {

  users.users.${username}.extraGroups = [ "kvm" "libvirtd" ];

  # Kernel Samepage Merging for deduplicating VM memory pages
  hardware.ksm.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.vm-curator.packages.${pkgs.system}.default
    qemu
    spice
    spice-gtk
    spice-protocol
    swtpm
    virt-viewer
    virtio-win
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu;
        runAsRoot = true;
        # Enable software TPM support for Windows 11.
        swtpm.enable = true;
      };
    };
    # Enable USB redirection. This can be used with any Spice client.
    spiceUSBRedirection.enable = true;
  };

  #+----- Impermanence Persistence -------------
  # Modular persistence: persist virtual machine disks and configurations
  environment.persistence."/persistent" = {
    users.${username} = {
      directories = [
        "VMs"
      ];
    };
  };
}
