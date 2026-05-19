{
  inputs,
  ...
}:
{
  flake.modules.homeManager.ai =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.codex
        pkgs.claude-code
      ];

      home.file.".config/opencode" = {
        source = ../../assets/opencode;
        force = true;
        recursive = true;
      };
    };
}
