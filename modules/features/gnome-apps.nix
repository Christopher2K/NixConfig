{
  flake.modules.nixos.gnome-apps =
    { ... }:
    {
      services.gvfs.enable = true;

      # Nautilus connects to the Tracker3 (localsearch/tinysparql) indexer at
      # startup. Without it, Nautilus blocks ~4.5s on a D-Bus activation
      # timeout for org.freedesktop.Tracker3.Miner.Files on first launch.
      # Enabling these provides the service (and working file search).
      services.gnome.tinysparql.enable = true;
      services.gnome.localsearch.enable = true;

      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };

  flake.modules.homeManager.gnome-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nautilus
        file-roller
        gnome-calculator
        gnome-text-editor
        loupe
        evince
      ];
    };
}
