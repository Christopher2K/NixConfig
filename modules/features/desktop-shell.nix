{ inputs, config, ... }:
let
  username = config.flake.username;
  helpers = config.flake.helpers;
in
{
  flake.modules.darwin.desktop-shell = {
    homebrew.casks = [
      "switchresx"
    ];
  };

  flake.modules.homeManager.desktop-shell =
    { pkgs, config, ... }:
    let
      colors = config.lib.stylix.colors.withHashtag;
      mkTheme = {
        name = "Stylix";
        primary = colors.base0D;
        primaryText = colors.base00;
        primaryContainer = colors.base0C;
        secondary = colors.base0E;
        surface = colors.base01;
        surfaceText = colors.base05;
        surfaceVariant = colors.base02;
        surfaceVariantText = colors.base04;
        surfaceTint = colors.base0D;
        background = colors.base00;
        backgroundText = colors.base05;
        outline = colors.base03;
        surfaceContainer = colors.base01;
        surfaceContainerHigh = colors.base02;
        surfaceContainerHighest = colors.base03;
        error = colors.base08;
        warning = colors.base0A;
        info = colors.base0C;
      };
    in
    {
      imports = [
        inputs.dms.homeModules.dank-material-shell
        inputs.dms.homeModules.niri
        inputs.dms-plugin-registry.homeModules.default
      ];

      programs.dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;
        dgop.package = inputs.dgop.packages.${pkgs.system}.default;

        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        niri.includes = {
          enable = true;
          override = false;
        };

        enableVPN = false;
        enableDynamicTheming = false;
        enableClipboardPaste = false;

        settings = {
          currentThemeName = "custom";
          customThemeFile = pkgs.writeText "dms-stylix-theme.json" (
            builtins.toJSON {
              dark = mkTheme;
              light = mkTheme;
            }
          );

          useAutoLocation = true;
          fontFamily = config.stylix.fonts.monospace.name;
          nightModeEnabled = false;
          widgetOutlineEnabled = true;
        };

        session = {
          wallpaperPath = "${config.home.homeDirectory}/.config/wallpapers/wallpaper-1.jpg";
        };

        clipboardSettings = {
          disabled = true;
        };
      };
    };
}
