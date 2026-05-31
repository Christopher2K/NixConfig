{ inputs, config, ... }:
let
  username = config.flake.username;
  helpers = config.flake.helpers;
  overlays = [
    inputs.neovim-nightly-overlay.overlays.default
    inputs.devenv.overlays.default
    (final: prev: {
      sqlit = inputs.sqlit.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
in
{
  flake.modules.nixos.coding =
    { pkgs, ... }:
    {
      nixpkgs.overlays = overlays;

      programs.nix-ld.enable = true;
      programs.nix-ld.libraries = with pkgs; [
        brotli
        unixodbc
        libGL
        glib
        stdenv.cc.cc
        zlib
        openssl
        curl
        bzip2
        libffi
        sqlite
        readline
        xz
        libyaml
        gdbm
        ncurses
        attr
        acl
        libsodium
        util-linux
        libssh
        libxml2
        zstd
      ];

      users.users.${username}.extraGroups = [ "kvm" ];
      environment.systemPackages = with pkgs; [
        jetbrains.idea
      ];
      nixpkgs.config.android_sdk.accept_license = true;
    };

  flake.modules.darwin.coding = {
    nixpkgs.overlays = overlays;

    homebrew.brews = [
      "xcodegen"
      "libyaml"
      "gh"
    ];

    homebrew.casks = [
      "android-studio"
      "ungoogled-chromium"
      "localcan"
      "xcodes-app"
    ];
  };

  flake.modules.homeManager.coding = helpers.mkHybrid {
    common =
      { pkgs, config, ... }:
      {
        home.file."${helpers.mkConfigPath config "/nvim"}".source = config.lib.file.mkOutOfStoreSymlink (
          helpers.mkAssetsStringPath config "/nvim"
        );

        home.file."${helpers.mkConfigPath config "/git/gitconfig-cookunity"}" = {
          source = helpers.mkAssetsPath "/gitconfig-cookunity";
          force = true;
        };

        home.packages = [
          pkgs.devenv
          pkgs.lazydocker
          pkgs.lazygit
          pkgs.sqlit
          pkgs.zed-editor
        ]
        ++ [
          inputs.tree-sitter.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        programs.neovim = {
          enable = true;
          package = pkgs.neovim;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          # Avoid HM writing ~/.config/nvim/init.lua (conflicts with our
          # out-of-store symlink to assets/nvim). HM's auto-generated initLua
          # (provider disables, plugin configs) is injected via a wrapper
          # --cmd flag instead.
          sideloadInitLua = true;
        };

        programs.mise = {
          enable = true;
          enableZshIntegration = true;
          globalConfig = {
            settings = {
              all_compile = false;
            };
            tools = {
              bun = "1.3.11";
              elixir = "1.18.4-otp-28";
              erlang = "28.0.2";
              gleam = "1.13.0";
              java = "openjdk-17.0.2";
              kotlin = "2.0.0";
              nodejs = "24.13.0";
              python = "3.12.0";
              ruby = "3.2.9";
              rust = "1.75.0";
              golang = "1.26.0";
            };
          };
        };

        programs.git = {
          enable = true;
          ignores = [
            ".bloop/"
            ".DS_STORE"
          ];
          settings = {
            user.email = "me@christopher2k.dev";
            user.name = "Christopher N. Katoyi Kaba";
            pull.rebase = true;
            init.defaultBranch = "main";
            rerere.enabled = true;
          };

          includes = [
            {
              path = helpers.mkConfigPath config "/git/gitconfig-cookunity";
              condition = "gitdir:**/cookunity/**";
            }
          ];
        };

        programs.direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
          mise.enable = true;
        };
      };

    darwin =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          orbstack
          tableplus
        ];
      };

    linux =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          ungoogled-chromium # for MCP and stuff
        ];
      };
  };
}
