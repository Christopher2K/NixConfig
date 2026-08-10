{
  config,
  inputs,
  ...
}:
let
  helpers = config.flake.helpers;
in
{
  flake.modules.homeManager.ai = helpers.mkHybrid {
    common =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.codex
          pkgs.claude-code
        ];

        home.file.".config/opencode" = {
          source = helpers.mkAssetsPath "/opencode";
          force = true;
          recursive = true;
        };
      };

    # Linux opencode.json is linked by the pen module (pen.nix), which injects
    # the pencil MCP server path at build time.
    darwin =
      { ... }:
      {
        home.file.".config/opencode/opencode.json".source =
          helpers.mkAssetsPath "/opencode-config/opencode.darwin.json";
      };
  };
}
