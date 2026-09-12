{ config, ... }:
let
  helpers = config.flake.helpers;
in
{
  # System level: adb for physical device debugging.
  # uaccess rules are handled automatically by systemd 258 (programs.adb was removed).
  flake.modules.nixos.android =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        # The Android Emulator's bundled qemu links against these libraries,
        # which are missing from steam-run's default FHS environment.
        (final: prev: {
          steam = prev.steam.override {
            extraPkgs = p: [
              p.nss
              p.nspr
              p.libxkbfile
              p.xcb-util-cursor
              p.xorg.libICE
              p.xorg.libSM
            ];
          };
        })
      ];
      environment.systemPackages = [ pkgs.android-tools ];
    };

  # User level: the IDE (Linux only; macOS keeps the Homebrew cask in coding.nix)
  flake.modules.homeManager.android = helpers.mkHybrid {
    linux =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.android-studio
          pkgs.android-cli
        ];
      };
  };
}
