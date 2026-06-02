{ inputs, config, ... }:
let
  username = config.flake.username;
  helpers = config.flake.helpers;
  overlays = [
    (final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
in
{
  flake.modules.nixos.terminal =
    { pkgs, ... }:
    {
      console.useXkbConfig = true;
      programs.zsh.enable = true;
      users.users.${username}.shell = pkgs.zsh;

      nixpkgs.overlays = overlays;
    };

  flake.modules.darwin.terminal = {
    nixpkgs.overlays = overlays;
  };

  flake.modules.homeManager.terminal =

    helpers.mkHybrid {
      darwin = {
        home.sessionVariables = {
          # Android
          ANDROID_ROOT = "$HOME/Library/Android";
          ANDROID_SDK_ROOT = "$HOME/Library/Android/sdk";
          ANDROID_PLATFORM_TOOLS = "$HOME/Library/Android/sdk/platform-tools";
          ANDROID_HOME = "$HOME/Library/Android/sdk";
        };
      };

      linux =
        {
          pkgs,
          lib,
          ...
        }:
        {
          home.sessionVariables = {
            # Android
            ANDROID_ROOT = "$HOME/Android";
            ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
            ANDROID_PLATFORM_TOOLS = "$HOME/Android/Sdk/platform-tools";
            ANDROID_HOME = "$HOME/Android/Sdk";

            # The manually-installed Android emulator (~/Android/Sdk/emulator) ships
            # pre-built FHS binaries whose Qt "xcb" platform plugin dlopen()s X/xcb
            # libraries that don't exist on NixOS. nix-ld doesn't help here because it
            # only patches the ELF interpreter for executables, not runtime dlopen of
            # Qt plugins. Expose the needed libraries via LD_LIBRARY_PATH so the
            # emulator GUI can start. (Use `-gpu swiftshader_indirect` if hardware
            # Vulkan rendering fails with VK_ERROR_INCOMPATIBLE_DRIVER.)
            LD_LIBRARY_PATH = lib.makeLibraryPath (
              with pkgs;
              [
                libxcb-cursor
                libxcb-image
                libxcb-keysyms
                libxcb-render-util
                libxcb-wm
                libxkbcommon
                libxcb
                libx11
                libxi
                libxext
                libice
                libsm
              ]
            );
          };
        };

      common =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          home.packages = with pkgs; [
            zjstatus
          ];

          home.file."${helpers.mkHomePath config "/Scripts"}" = {
            source = helpers.mkAssetsPath "/scripts";
            recursive = true;
            force = true;
          };

          home.file."${helpers.mkConfigPath config "/.env.template"}" = {
            source = helpers.mkAssetsPath "/env.template";
            force = true;
          };

          home.sessionVariables = {
            LC_ALL = "en_US.UTF-8";
            LC_CTYPE = "en_US.UTF-8";
            TMPDIR = "$HOME/.tmp";

            DEV = "$HOME/Developer";

            SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-agent.sock";

            SHELL_SESSIONS_DISABLE = 1;
            PATH = "$PATH:$ANDROID_PLATFORM_TOOLS:$HOME/Library/Android/sdk/emulator";

            # Erlang
            ERL_AFLAGS = "-kernel shell_history enabled";

            TERMINAL = "ghostty";
          };

          home.shell.enableShellIntegration = true;

          programs.ghostty = {
            enable = true;
            package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
            enableZshIntegration = true;
            settings = {
              macos-titlebar-style = "hidden";
              macos-option-as-alt = true;
              window-padding-x = 12;
              window-padding-y = 12;
              working-directory = "home";
              window-inherit-working-directory = false;
              window-save-state = "never";
            };
          };

          programs.zsh = {
            enable = true;
            oh-my-zsh.enable = true;

            # Enable built-in completions (faster than oh-my-zsh)
            enableCompletion = false;
            completionInit = ''
              autoload -Uz compinit
              # Only regenerate .zcompdump once a day for faster startup
              if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
                compinit
              else
                compinit -C
              fi
            '';

            shellAliases = {
              "switch" =
                if pkgs.stdenv.isDarwin then "sudo darwin-rebuild switch" else "sudo nixos-rebuild switch";

              # Git aliases (replacing oh-my-zsh git plugin - only the commonly used ones)
              g = "git";
              ga = "git add";
              gaa = "git add --all";
              gb = "git branch";
              gc = "git commit";
              gcm = "git commit -m";
              gco = "git checkout";
              gd = "git diff";
              gf = "git fetch";
              gl = "git pull";
              gp = "git push";
              gst = "git status";
              glog = "git log --oneline --decorate --graph";
            };

            initContent =
              let
                zshConfigEarlyInit = lib.mkOrder 500 ''
                  source ~/.runtimerc 2>/dev/null || true

                  delete_localonly_branches () {
                    git fetch -p

                    for branch in $(git branch --format "%(refname:short)"); do
                      if ! git show-ref --quiet refs/remotes/origin/$branch; then
                        echo "Delete local $branch"
                        git branch -D $branch
                      fi
                    done
                  }

                  alias delete_localonly_branch="delete_localonly_branches"

                  # Load cached environment variables
                  CACHE_FILE="$HOME/.cache/env/.env.cache"

                  if [ -f "$CACHE_FILE" ]; then
                    source "$CACHE_FILE"
                  else
                    echo "⚠️  No cached environment variables found. Running: ~/Scripts/secure-env-refresh"
                    ~/Scripts/secure-env-refresh.sh
                    source "$CACHE_FILE"
                  fi
                '';
              in
              lib.mkMerge [
                zshConfigEarlyInit
              ];
          };

          programs.starship = {
            enable = true;
            settings = {
              command_timeout = 1000;
              format = "$character$directory";
              right_format = "$all";

              # Disable slow/unused modules for faster prompt rendering
              ruby.detect_variables = [ ];
              aws.disabled = true;
              gcloud.disabled = true;
              package.disabled = true;

              cmd_duration = {
                min_time = 0;
                show_milliseconds = false;
              };

              # Git optimizations - only check in git dirs, skip slow operations
              git_status = {
                disabled = false;
                ignore_submodules = true;
              };
            };
          };

          programs.zellij = {
            enable = true;
            enableZshIntegration = false;
            attachExistingSession = false;
            layouts = {
              default = {
                layout = {
                  _children = [
                    {
                      default_tab_template = {
                        _children = [
                          {
                            pane = {
                              size = 1;
                              borderless = true;
                              plugin = {
                                location = "file:${pkgs.zjstatus}/bin/zjstatus.wasm";
                                format_left = "{mode}#[fg=#7F6E63,bg=#d5c4a1]#[fg=#FFFFFF,bold,bg=#7F6E63] {session} #[fg=#7F6E63,bg=#d5c4a1]{tabs}";
                                format_right = "#[fg=#a89984,bg=#d5c4a1]#[fg=#ffffff,bold,bg=#a89984] {datetime} #[fg=#a89984,bg=#d5c4a1]";
                                format_space = "";

                                border_enabled = "false";
                                border_char = "─";
                                border_format = "#[fg=#a89984]{char}";
                                border_position = "top";

                                hide_frame_for_single_pane = "true";

                                mode_normal = "#[bg=#d5c4a1]";
                                mode_tmux = "#[fg=#af3a03,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#af3a03]  #[fg=#af3a03,bg=#d5c4a1]";
                                mode_locked = "#[fg=#af3a03,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#af3a03]  #[fg=#af3a03,bg=#d5c4a1]";
                                mode_pane = "#[fg=#458588,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#458588] PANE #[fg=#458588,bg=#d5c4a1]";
                                mode_tab = "#[fg=#d79921,bg=#d5c4a1]#[fg=#3c3836,bold,bg=#d79921] TAB #[fg=#d79921,bg=#d5c4a1]";
                                mode_resize = "#[fg=#b16286,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#b16286] RESIZE #[fg=#b16286,bg=#d5c4a1]";
                                mode_move = "#[fg=#689d6a,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#689d6a] MOVE #[fg=#689d6a,bg=#d5c4a1]";
                                mode_scroll = "#[fg=#458588,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#458588] SCROLL #[fg=#458588,bg=#d5c4a1]";
                                mode_search = "#[fg=#d65d0e,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#d65d0e] SEARCH #[fg=#d65d0e,bg=#d5c4a1]";
                                mode_enter_search = "#[fg=#d65d0e,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#d65d0e] ENTER SEARCH #[fg=#d65d0e,bg=#d5c4a1]";
                                mode_rename_tab = "#[fg=#d79921,bg=#d5c4a1]#[fg=#3c3836,bold,bg=#d79921] RENAME TAB #[fg=#d79921,bg=#d5c4a1]";
                                mode_rename_pane = "#[fg=#458588,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#458588] RENAME PANE #[fg=#458588,bg=#d5c4a1]";
                                mode_session = "#[fg=#98971a,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#98971a] SESSION #[fg=#98971a,bg=#d5c4a1]";
                                mode_prompt = "#[fg=#b16286,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#b16286] PROMPT #[fg=#b16286,bg=#d5c4a1]";

                                tab_normal = "#[fg=#a89984,bg=#d5c4a1]#[fg=#ebdbb4,bg=#a89984] {index} {name} #[fg=#a89984,bg=#d5c4a1]";
                                tab_active = "#[fg=#af3a03,bg=#d5c4a1]#[fg=#ebdbb2,bold,bg=#af3a03] {index} {name} #[fg=#af3a03,bg=#d5c4a1]";
                                tab_separator = "";

                                datetime = "{format}";
                                datetime_format = "%d %b %H:%M";
                                datetime_timezone = "local";
                              };
                            };
                          }
                          { "children" = { }; }
                        ];
                      };
                    }
                  ];
                };
              };
            };

            settings = {
              theme = "gruvbox-light";
              simplified_ui = true;
              default_shell = "zsh";
              copy_on_select = true;
              show_startup_tips = false;
            };

            extraConfig = ''
              keybinds {
                normal clear-defaults=true {
                  bind "Ctrl b" { SwitchToMode "Tmux"; }

                  bind "Alt f" { ToggleFloatingPanes; }
                  bind "Alt n" { NewPane; }
                  bind "Alt i" { MoveTab "Left"; }
                  bind "Alt o" { MoveTab "Right"; }
                  bind "Alt h" { MoveFocusOrTab "Left"; }
                  bind "Alt l" { MoveFocusOrTab "Right"; }
                  bind "Alt j" { MoveFocus "Down"; }
                  bind "Alt k" { MoveFocus "Up"; }
                  bind "Alt =" "Alt +" { Resize "Increase"; }
                  bind "Alt -" { Resize "Decrease"; }
                  bind "Alt [" { PreviousSwapLayout; }
                  bind "Alt ]" { NextSwapLayout; }
                  bind "Alt p" { TogglePaneInGroup; }
                  bind "Alt Shift p" { ToggleGroupMarking; }
                }

                tmux clear-defaults=true {
                  bind "Ctrl b" { Write 2; SwitchToMode "Normal"; }
                  bind "Esc" { SwitchToMode "Normal"; }
                  bind "g" { SwitchToMode "Locked"; }
                  bind "p" { SwitchToMode "Pane"; }
                  bind "t" { SwitchToMode "Tab"; }
                  bind "r" { SwitchToMode "Resize"; }
                  bind "m" { SwitchToMode "Move"; }
                  bind "s" { SwitchToMode "Scroll"; }
                  bind "o" { SwitchToMode "Session"; }
                  bind "q" { Quit; }

                  bind "Ctrl n" "n" { GoToNextTab; SwitchToMode "Normal"; }
                  bind "Ctrl p" "p" { GoToPreviousTab; SwitchToMode "Normal"; }
                  bind "Ctrl 1" "1" { GoToTab 1; SwitchToMode "Normal"; }
                  bind "Ctrl 2" "2" { GoToTab 2; SwitchToMode "Normal"; }
                  bind "Ctrl 3" "3" { GoToTab 3; SwitchToMode "Normal"; }
                  bind "Ctrl 4" "4" { GoToTab 4; SwitchToMode "Normal"; }
                  bind "Ctrl 5" "5" { GoToTab 5; SwitchToMode "Normal"; }
                  bind "Ctrl 6" "6" { GoToTab 6; SwitchToMode "Normal"; }
                  bind "Ctrl 7" "7" { GoToTab 7; SwitchToMode "Normal"; }
                  bind "Ctrl 8" "8" { GoToTab 8; SwitchToMode "Normal"; }
                  bind "Ctrl 9" "9" { GoToTab 9; SwitchToMode "Normal"; }
                }
              }
            '';
          };

        };
    };
}
