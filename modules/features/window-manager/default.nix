{ inputs, config, ... }:
let
  helpers = config.flake.helpers;
  username = config.flake.username;
in
{
  flake.modules.nixos.window-manager =
    { pkgs, ... }:
    {

      nixpkgs.overlays = [
        inputs.niri.overlays.niri
      ];

      xdg.portal = {
        enable = true;
        config.common.default = [ "gnome" ];
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
      };

      services.displayManager.dms-greeter = {
        enable = true;
        compositor.name = "niri";
        package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
        configHome = "/home/${username}";
      };

      programs.niri.enable = true;
    };

  flake.modules.darwin.window-manager =
    { ... }:
    {
    };

  flake.modules.homeManager.window-manager = helpers.mkHybrid {
    linux = import ./_window-manager.linux.nix { inherit inputs helpers; };
    darwin = import ./_window-manager.darwin.nix { inherit inputs helpers; };
  };
}
