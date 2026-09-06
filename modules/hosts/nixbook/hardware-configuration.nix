{
  inputs,
  config,
  ...
}:
{
  flake.nixosModules.nixbookHardware =
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

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/1e35732a-3f88-42b3-808d-2c8d6ca6793f";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/A415-1A0A";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      fileSystems."/data" = {
        device = "/dev/disk/by-uuid/695191cc-9e34-418c-b3bc-0c793b38fb40";
        fsType = "ext4";
      };

      swapDevices = [ ];

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
    };
}
