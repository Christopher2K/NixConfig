{ inputs, helpers }:
{ pkgs, config, ... }:
{

  home.file."${helpers.mkConfigPath config "/omniwm/settings.json"}" = {
    source = helpers.mkAssetsPath "/omniwm-settings.json";
    force = true;
  };

  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    launchd.keepAlive = true;

    settings = {
      after-startup-command = [ "layout accordion" ];
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      accordion-padding = 30;
      default-root-container-layout = "accordion";
      default-root-container-orientation = "horizontal";
      automatically-unhide-macos-hidden-apps = true;
      key-mapping.preset = "qwerty";

      gaps = {
        inner.horizontal = 12;
        inner.vertical = 12;
        outer.left = 12;
        outer.bottom = 12;
        outer.top = 12;
        outer.right = 12;
      };

      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";
        alt-shift-minus = "resize smart -50";
        alt-shift-equal = "resize smart +50";
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-m = "workspace M";
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-m = "move-node-to-workspace M";
        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
        alt-shift-semicolon = "mode service";
      };

      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];
      };

      # App-specific workspace assignments
      workspace-to-monitor-force-assignment = {
        "1" = [ "main" ];
        "2" = [ "main" ];
        "3" = [ "main" ];
        "4" = [ "main" ];
        "5" = [ "secondary" ];
        "6" = [ "secondary" ];
        "7" = [ "secondary" ];
        "M" = [ "secondary" ];
      };

      # Window detection for specific apps
      on-window-detected = [
        {
          "if".app-id = "com.1password.1password";
          run = [ "move-node-to-workspace M" ];
        }
      ];
    };
  };

  services.jankyborders = {
    enable = true;
    settings = {
      active_color = "0xfffe8019";
      inactive_color = "0x00000000";
      hidpi = true;
      style = "round";
      width = 10.0;
      ax_focus = true;
      blacklist = "idea, studio";
    };
  };
}
