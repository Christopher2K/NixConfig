{ inputs, config, ... }:
let
  darwin = config.flake.modules.darwin;
  hm = config.flake.modules.homeManager;
  username = config.flake.username;
  helpers = config.flake.helpers;
in
{
  flake.darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      inputs.nix-homebrew.darwinModules.nix-homebrew

      # system-level configuration
      darwin.coding
      darwin.communication
      darwin.design
      darwin."3d-design"
      darwin.desktop-shell
      darwin.homebrew
      darwin.launcher
      darwin.macbookConfiguration
      darwin.productivity
      darwin.security
      darwin.storage
      darwin.streaming
      darwin.terminal
      darwin.theme
      darwin.window-manager

      inputs.home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.users.${username} = {
          imports = [
            hm.ai
            hm.browser
            hm.christopher
            hm.cli-tooling
            hm.coding
            hm.communication
            hm.notes
            hm.security
            hm.streaming
            hm.terminal
            hm.theme
            hm.window-manager
          ];
        };
      }
    ];
  };
}
