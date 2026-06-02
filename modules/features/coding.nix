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
    let
      # niri (Wayland/wlroots) + JBR 21: the IDE initializes fully but never
      # maps a window, then exits with code 130 (SIGINT). JBR ships an
      # experimental native Wayland AWT toolkit that must be opted into via the
      # *_VM_OPTIONS file (see assets/android-studio/studio64.vmoptions). We
      # point STUDIO_VM_OPTIONS at it so the toolkit flags apply regardless of
      # the versioned per-user config dir.
      studioVmOptions = helpers.mkAssetsPath "/android-studio/studio64.vmoptions";

      # Primary launcher: force JBR native Wayland.
      androidStudioWayland = pkgs.symlinkJoin {
        name = "android-studio-wayland";
        paths = [ pkgs.android-studio ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/android-studio \
            --set STUDIO_VM_OPTIONS ${studioVmOptions} \
            --set _JAVA_AWT_WM_NONREPARENTING 1
        '';
      };

      # Fallback companion: route through the already-running xwayland-satellite.
      # Use this to compare if niri still refuses to map the Wayland surface.
      # Exposes only `android-studio-xwayland` (no collision with the primary
      # `android-studio` binary) and forces the X11 AWT toolkit.
      androidStudioXwayland =
        pkgs.runCommand "android-studio-xwayland"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p $out/bin
            makeWrapper ${pkgs.android-studio}/bin/android-studio $out/bin/android-studio-xwayland \
              --set _JAVA_AWT_WM_NONREPARENTING 1 \
              --set-default DISPLAY ":0" \
              --add-flags "-Dawt.toolkit.name=XToolkit"
          '';
    in
    {
      nixpkgs.overlays = overlays;

      programs.nix-ld.enable = true;
      programs.nix-ld.libraries = with pkgs; [
        acl
        alsa-lib
        attr
        at-spi2-core
        brotli
        bzip2
        cairo
        curl
        cups
        dbus
        expat
        gdbm
        glib
        gtk3
        libGL
        libffi
        libsodium
        libgbm
        libssh
        libbsd
        libxml2
        libxkbfile
        libpng
        libdrm
        libxkbcommon
        libpulseaudio
        libyaml
        ncurses
        nspr
        nss
        mesa
        openssl
        pango
        readline
        sqlite
        stdenv.cc.cc
        unixodbc
        util-linux
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libxcb
        xz
        zlib
        zstd
      ];

      users.users.${username}.extraGroups = [ "kvm" ];
      environment.systemPackages = [
        pkgs.jetbrains.idea
        androidStudioWayland
        androidStudioXwayland
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
