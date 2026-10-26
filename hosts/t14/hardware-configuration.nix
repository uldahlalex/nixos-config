# PLACEHOLDER — not generated on the real machine yet.
#
# Before building `.#t14`, boot a NixOS installer on the actual ThinkPad,
# partition/mount the disks, then run:
#
#   nixos-generate-config --root /mnt
#
# and replace this entire file with the one it writes to
# /mnt/etc/nixos/hardware-configuration.nix (it will have the correct
# disk UUIDs and the kernel modules this specific laptop's installer
# detected — NVMe, Wi-Fi card, etc.).
#
# The AMD-specific bits below (kvm-amd, amd.updateMicrocode) are a
# reasonable starting point for the Ryzen AI 350 and should carry over,
# but let the generated file be the source of truth.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/eea933a4-57d1-4987-9cf2-e313a6c9d4f8";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/FF10-C3B2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
