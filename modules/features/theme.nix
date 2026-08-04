{
  config,
  inputs,
  ...
}:
let
  helpers = config.flake.helpers;
in
{
  flake.modules.nixos.theme = {
    imports = [
      inputs.stylix.nixosModules.stylix
    ];
  };

  flake.modules.darwin.theme = {
    imports = [
      inputs.stylix.darwinModules.stylix
    ];
  };

  flake.modules.homeManager.theme = helpers.mkHybrid {
    common =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.stylix.homeModules.stylix
        ];

        home.packages = with pkgs; [
          base16-schemes
        ];

        stylix = {
          enable = true;
          autoEnable = false;
          polarity = "dark";
          base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

          cursor = {
            size = 32;
            name = "phinger-cursors";
            package = pkgs.phinger-cursors;
          };
          fonts = {
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = "JetBrainsMono Nerd Font Mono";
            };
            sansSerif = config.stylix.fonts.monospace;
            serif = config.stylix.fonts.monospace;
            emoji = {
              package = pkgs.whatsapp-emoji-font;
              name = "WhatsAppEmoji";
            };

            sizes = {
              terminal = 10;
              desktop = 10;
              applications = 10;
            };
          };
        };

        # Common stylix targets
        stylix.targets.kitty.enable = true;
        stylix.targets.fontconfig.enable = true;
        stylix.targets.starship.enable = true;
        stylix.targets.vesktop.enable = true;
      };

    linux =
      { pkgs, ... }:
      {
        gtk = {
          enable = true;
          iconTheme = {
            package = pkgs.gruvbox-plus-icons;
            name = "Gruvbox-Plus-Dark";
          };
        };

        qt = {
          enable = true;
        };

        stylix.targets.gnome.enable = true;
        stylix.targets.gtk.enable = true;
        stylix.targets.qt.enable = true;
        stylix.targets.vicinae.enable = true;
      };

    darwin = { };
  };
}
