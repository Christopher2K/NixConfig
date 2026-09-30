{ config, ... }:
let
  helpers = config.flake.helpers;
  localApiKey = "sk-local-opencode";
  localManagementKey = "sk-local-management";
in
{
  flake.modules.darwin.ai-router = { };

  flake.modules.homeManager.ai-router =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cliproxyapi = pkgs.stdenvNoCC.mkDerivation {
        pname = "cliproxyapi";
        version = "8.0.6";

        src = pkgs.fetchurl {
          url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v8.0.6/CLIProxyAPI_8.0.6_darwin_aarch64.tar.gz";
          hash = "sha256-4Z9zTNAHWZUe2osNshMBp4QpI7A6EPj6iDwZwnbkFpM=";
        };

        sourceRoot = ".";
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 cli-proxy-api "$out/bin/cliproxyapi"
          runHook postInstall
        '';
      };
    in
    {
      home.packages = [ cliproxyapi ];

      home.file.".config/cliproxyapi/config.yaml".text = ''
        config-version: 8

        server:
          host: "127.0.0.1"
          port: 8317
          discovery:
            enabled: false

        management:
          allow-remote: false
          secret-key: "${localManagementKey}"
          disable-control-panel: false

        access:
          api-keys:
            - "${localApiKey}"

        observability:
          logs:
            debug: false
            request-log: false
            logging-to-file: false
          usage:
            usage-statistics-enabled: false

        routing:
          strategy: "round-robin"
          session-affinity: true
          session-affinity-ttl: "1h"

        oauth:
          auth-dir: "~/.cli-proxy-api"
      '';

      home.file.".config/opencode/opencode.json".source = lib.mkForce (
        helpers.mkAssetsPath "/opencode-config/opencode.cookunity.json"
      );

      home.activation.cliproxyapiCredentialPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        auth_dir="${config.home.homeDirectory}/.cli-proxy-api"
        $DRY_RUN_CMD mkdir -p "$auth_dir"
        $DRY_RUN_CMD chmod 700 "$auth_dir"
        for credential in "$auth_dir"/*.json; do
          if [ -e "$credential" ]; then
            $DRY_RUN_CMD chmod 600 "$credential"
          fi
        done
      '';

      launchd.agents.cliproxyapi = {
        enable = true;
        config = {
          ProgramArguments = [
            "${cliproxyapi}/bin/cliproxyapi"
            "--config"
            "${config.home.homeDirectory}/.config/cliproxyapi/config.yaml"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          Umask = 63;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/cliproxyapi.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/cliproxyapi.log";
        };
      };
    };
}
