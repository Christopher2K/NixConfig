{ inputs, config, ... }:
let
  helpers = config.flake.helpers;
  tailscaleConfig = {
    services.tailscale = {
      enable = true;
    };
  };
in
{
  flake.modules.nixos.security =
    { pkgs, ... }:
    {
      services.howdy = {
        enable = true;
        settings.core.device = "/dev/video2";
      };
      security.pam.howdy.enable = false;
      security.pam.services.login.enableGnomeKeyring = true;
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.sudo.howdy = {
        enable = true;
        control = "sufficient";
      };
    }
    // tailscaleConfig;

  flake.modules.darwin.security = {
    security.pam.services.sudo_local = {
      enable = true;
      reattach = true;
      touchIdAuth = true;
    };
  }
  // tailscaleConfig;

  flake.modules.homeManager.security = helpers.mkHybrid {
    common =
      { pkgs, ... }:
      {
        home.sessionVariables = {
          SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-agent.sock";
        };

        home.packages = [
          pkgs.proton-pass
          pkgs.proton-pass-cli
        ];
      };

    linux =
      { pkgs, ... }:
      {
        home.sessionVariables = {
          # Temporary fix for https://github.com/NixOS/nixpkgs/issues/497155
          PROTON_PASS_KEY_PROVIDER = "fs";
        };
        systemd.user.sessionVariables = {
          PROTON_PASS_KEY_PROVIDER = "fs";
        };

        systemd.user.services.proton-pass-ssh-agent = {
          Unit = {
            Description = "Proton Pass SSH agent";
            After = [ "default.target" ];
          };
          Service = {
            ExecStart = "${pkgs.proton-pass-cli}/bin/pass-cli ssh-agent start";
            Restart = "on-failure";
            RestartSec = "5s";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };

        systemd.user.services.gnome-keyring-daemon = {
          Unit = {
            Description = "GNOME Keyring daemon";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,pkcs11";
            Restart = "on-failure";
            RestartSec = "1s";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };

    darwin =
      { pkgs, config, ... }:
      {
        launchd.agents.pass-cli-ssh-agent = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.proton-pass-cli}/bin/pass-cli"
              "ssh-agent"
              "start"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/pass-cli-ssh-agent.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/pass-cli-ssh-agent.log";
          };
        };
      };
  };
}
