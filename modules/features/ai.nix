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
      let
        system = pkgs.stdenv.hostPlatform.system;
        opencodePkgs = inputs.opencode.packages.${system};
        # Workarounds for v2.0.2 (re-tagged 2026-09-12). Remove once upstream
        # fixes its nix packaging:
        # 1. stale node_modules FOD hash for x86_64-linux (hashes.json).
        brokenHashes = {
          x86_64-linux = "sha256-QJn59dTbxspHl35vGxs6akynlfaWaPqvbMNsi0EqnbM=";
        };
        # 2. installPhase references dist/cli-*/bin/opencode2, but build.ts
        #    names the binary "opencode".
        installPhaseFix =
          prev:
          builtins.replaceStrings [ "dist/cli-*/bin/opencode2" ] [ "dist/cli-*/bin/opencode" ]
            prev.installPhase;
        opencode =
          (
            if builtins.hasAttr system brokenHashes then
              opencodePkgs.opencode.override {
                node_modules = opencodePkgs.opencode.node_modules.override {
                  hash = brokenHashes.${system};
                };
              }
            else
              opencodePkgs.default
          ).overrideAttrs
            (prev: {
              installPhase = installPhaseFix prev;
              # Upstream nix packaging installs the binary as "opencode2"; keep
              # an "opencode" alias for existing configs (e.g. nvim terminal).
              postInstall = (prev.postInstall or "") + ''
                ln -s $out/bin/opencode2 $out/bin/opencode
              '';
            });
      in
      {
        home.packages = [
          opencode
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
