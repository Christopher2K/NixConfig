{ config, ... }:
let
  helpers = config.flake.helpers;
  monitors = {
    builtin-laptop = "Samsung Display Corp. ATNA40CU05-0  Unknown";
    lg-home = "LG Electronics LG ULTRAGEAR+ 406NTWGBQ649";
    capture-card = "Elgato Systems LLC HD60 X Unknown";
  };
in
{
  flake.modules.homeManager.monitor-config = helpers.mkHybrid {
    linux =
      { pkgs, ... }:
      let
        niri-reorder-workspaces = pkgs.writeShellScriptBin "niri-reorder-workspaces" ''
          set -euo pipefail
          sleep 1
          ${pkgs.niri}/bin/niri msg action move-workspace-to-index --reference stream 1
          ${pkgs.niri}/bin/niri msg action move-workspace-to-index --reference misc 2
          ${pkgs.niri}/bin/niri msg action move-workspace-to-index --reference main 3
          ${pkgs.niri}/bin/niri msg action move-workspace-to-index --reference secondary 4
          ${pkgs.niri}/bin/niri msg action move-workspace-to-index --reference scratch 5
        '';
        get-output-by-description = pkgs.writeShellScriptBin "get-output-by-description" ''
          set -euo pipefail

          if [ -z "''${1:-}" ]; then
            echo "Usage: get-output-by-description <description>" >&2
            exit 1
          fi

          description="$1"

          output=$(${pkgs.niri}/bin/niri msg -j outputs | ${pkgs.jq}/bin/jq -r --arg desc "$description" '
            to_entries[] |
            select(
              ((.value.make + " " + .value.model + " " + (.value.serial // "Unknown")) | gsub("\\s+"; " ") | gsub("^ | $"; "")) 
              == 
              ($desc | gsub("\\s+"; " ") | gsub("^ | $"; ""))
            ) | .key
          ')

          if [ -z "$output" ]; then
            echo "Error: No output found matching description: $description" >&2
            exit 1
          fi

          echo "$output"
        '';
        mirror-command = "exec wl-present mirror $(${get-output-by-description}/bin/get-output-by-description \"${monitors.builtin-laptop}\") --fullscreen-output $(${get-output-by-description}/bin/get-output-by-description \"${monitors.capture-card}\") --fullscreen";
        base-command = "exec pkill -i wl-mirror";
      in
      {
        home.packages = with pkgs; [
          wl-mirror
          get-output-by-description
          niri-reorder-workspaces
        ];
      };
  };
}
