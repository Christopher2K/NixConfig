{
  inputs,
  ...
}:
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.proton-cachyos.overlays.default
      ];

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [ proton-cachyos ];
      };
      programs.gamemode.enable = true;
    };

  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        goverlay
      ];

      programs.mangohud = {
        enable = true;
        # Session-wide injects MANGOHUD=1 and the MangoHud Vulkan layer into
        # every app (including all GTK apps), adding first-launch overhead
        # across the whole desktop. Enable per-game instead, e.g. the Steam
        # launch option `mangohud %command%` or the `mangohud` wrapper.
        enableSessionWide = false;
        settings = {
          legacy_layout = 0;
          background_alpha = 0.6;
          round_corners = 10;
          background_color = "000000";
          font_size = 25;
          text_color = "C0C0C0";
          position = "top-left";
          gpu_list = 0;
          table_columns = 3;
          gpu_text = "GPU";
          gpu_stats = true;
          gpu_load_change = true;
          gpu_load_value = [
            50
            90
          ];
          gpu_load_color = [
            "FFFFFF"
            "FFAA7F"
            "CC0000"
          ];
          vram = true;
          vram_color = "F1003B";
          gpu_power = true;
          gpu_color = "F1003B";
          cpu_text = "CPU";
          cpu_stats = true;
          cpu_load_change = true;
          cpu_load_value = [
            50
            90
          ];
          cpu_load_color = [
            "FFFFFF"
            "FFAA7F"
            "CC0000"
          ];
          cpu_power = true;
          cpu_color = "FA8000";
          ram = true;
          ram_color = "FA8000";
          fps = true;
          fps_limit_method = "late";
          toggle_fps_limit = "Shift_L+F1";
          fps_limit = 0;
          vsync = 4;
          log_duration = 30;
          log_interval = 100;
        };
      };
    };
}
