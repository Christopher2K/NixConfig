{ inputs, config, ... }:
let
  username = config.flake.username;
in
{
  flake.modules.nixos.nixbookConfiguration =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.nixosModules.nixbookHardware
      ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 5;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "nixbook";
      networking.wireless.enable = true;
      networking.networkmanager.enable = true;

      time.timeZone = "America/Toronto";

      i18n.defaultLocale = "en_CA.UTF-8";

      services.xserver.xkb = {
        layout = "us";
        variant = "altgr-intl";
        options = "caps:escape";
      };

      users.users.${username} = {
        isNormalUser = true;
        description = "Christopher Katoyi Kaba";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      nixpkgs.config.allowUnfree = true;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "christopher"
        ];
      };

      nix.gc.automatic = true;
      nix.gc.options = "--delete-older-than 7d";

      environment.systemPackages = with pkgs; [
        accountsservice
        appimage-run
        asusctl
        lm_sensors
        libgcc
        gcc
        gnumake
        wine
      ];

      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      system.stateVersion = "25.11";

      programs.nix-ld.enable = true;

      # power-profiles-daemon conflicts with asusd on ASUS laptops,
      # both fight over /sys/firmware/acpi/platform_profile.
      services.power-profiles-daemon.enable = false;
      services.upower.enable = true;

      services.supergfxd.enable = true;
      services.asusd.enable = true;
    };
}
