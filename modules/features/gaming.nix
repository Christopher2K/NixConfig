{
  inputs,
  ...
}:
let
  # The Ankama Launcher auto-updater only works when running as a real
  # AppImage: it needs $APPIMAGE to locate the file to replace. The nixpkgs
  # package runs the extracted AppImage in an FHS env where that variable is
  # unset, so as soon as upstream publishes a newer launcher the update task
  # throws and the launcher dies at startup with a fatal error.
  # Disable the updater by blanking its feed URL inside app.asar. The
  # replacement must keep the exact same byte length: asar archives store
  # files contiguously, so resizing main.js would corrupt the offsets.
  ankamaLauncherOverlay = final: prev: {
    ankama-launcher =
      let
        inherit (prev.ankama-launcher) pname version src;
        contents = prev.appimageTools.extract {
          inherit pname version src;
          postExtract = ''
            chmod +w $out/resources/app.asar
            old='autoupdaterUrl:"https://launcher.cdn.ankama.com/installers"'
            new='autoupdaterUrl:!1'
            pad=$(( ''${#old} - ''${#new} ))
            if [ "$pad" -lt 0 ]; then
              echo "ankama-launcher: updater patch target shrank, update the overlay" >&2
              exit 1
            fi
            new="$new$(printf "%''${pad}s" "")"
            if ! grep -aqF "$old" $out/resources/app.asar; then
              echo "ankama-launcher: updater feed URL not found in app.asar" >&2
              exit 1
            fi
            sed -i "s|autoupdaterUrl:\"https://launcher\.cdn\.ankama\.com/installers\"|$new|g" $out/resources/app.asar
          '';
        };
      in
      prev.appimageTools.wrapAppImage {
        inherit
          pname
          version
          src
          contents
          ;
        extraPkgs = pkgs: [ pkgs.wine ];
        extraInstallCommands = ''
          install -m 444 -D ${contents}/zaap.desktop $out/share/applications/ankama-launcher.desktop
          sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
          install -m 444 -D ${contents}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
        '';
        inherit (prev.ankama-launcher) meta;
      };
  };
in
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.proton-cachyos.overlays.default
        ankamaLauncherOverlay
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
        ankama-launcher
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
