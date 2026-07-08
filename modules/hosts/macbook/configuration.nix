{
  config,
  inputs,
  lib,
  ...
}:
let
  username = config.flake.username;
in
{
  flake.modules.darwin.macbookConfiguration = {
    # Disable nix-darwin self version management
    nix.enable = false;
    nixpkgs.hostPlatform = "aarch64-darwin";
    nixpkgs.config.allowUnfree = true;

    environment.etc.nix-darwin.source = "/Users/${username}/NixConfig";

    users.users.${username}.home = "/Users/${username}";

    power.sleep = {
      computer = "never";
      display = 30;
      harddisk = "never";
    };

    system = {
      primaryUser = username;
      # Set Git commit hash for darwin-version.
      configurationRevision = (config.rev or config.dirtyRev or null);

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      stateVersion = 6;

      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };
    };

    system.defaults = {
      spaces.spans-displays = false;
      dock.expose-group-apps = true; # For aerospace
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      dock = {
        autohide = true;
        launchanim = false;
        magnification = false;
        mru-spaces = false;
        orientation = "right";
        show-recents = false;
        tilesize = 36;
      };

      finder = {
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = false;
        NewWindowTarget = "Home";
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      WindowManager = {
        EnableTilingByEdgeDrag = false;
        EnableTilingOptionAccelerator = false;
        GloballyEnabled = false;
      };

      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        Display = false;
        FocusModes = false;
        Sound = true;
      };

      NSGlobalDomain = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSTableViewDefaultSizeMode = 1;
        _HIHideMenuBar = false;
        "com.apple.keyboard.fnState" = true;
      };

      CustomUserPreferences = {
        NSWindowShouldDragOnGesture.value = true;
      };
    };
  };
}
