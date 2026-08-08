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
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;

      darken =
        hex: amount:
        let
          h = builtins.substring 1 6 hex;
          channel = i: (builtins.fromTOML ("v = 0x" + builtins.substring (i * 2) 2 h)).v;
          digits = "0123456789abcdef";
          toHex2 = n: builtins.substring (n / 16) 1 digits + builtins.substring (lib.mod n 16) 1 digits;
          scale = v: builtins.floor (v * (1 - amount));
        in
        "#"
        + lib.concatMapStrings (v: toHex2 (scale v)) [
          (channel 0)
          (channel 1)
          (channel 2)
        ];

      mkTheme = {
        name = "Stylix";
        primary = colors.base0D;
        primaryText = colors.base00;
        # Dark shade of the accent so `primary` text stays readable on it
        primaryContainer = darken colors.base0D 0.6;
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
