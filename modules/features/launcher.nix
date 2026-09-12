{ inputs, config, ... }:
let
  helpers = config.flake.helpers;
in
{
  flake.modules.nixos.launcher = {
    nixpkgs.overlays = [
      inputs.vicinae.overlays.default
    ];
  };

  flake.modules.darwin.launcher = {
    homebrew.casks = [
      "raycast"
    ];
  };

  flake.modules.homeManager.launcher = helpers.mkHybrid {
    linux =
      { pkgs, ... }:
      {
        imports = [
          inputs.vicinae.homeManagerModules.default
        ];

        programs.vicinae = {
          enable = true;
          systemd = {
            enable = true;
            autoStart = true;
            environment = {
              USE_LAYER_SHELL = 1;
            };
          };
          settings = {
            font = {
              size = 11;
            };
          };
        };
      };
  };
}
