{
  inputs,
  ...
}:
{
  flake.modules.darwin.communication = {
    homebrew.casks = [
      "whatsapp"
      "signal"
      "slack"
      "insta360-link-controller"
      "zoom"
    ];
  };

  flake.modules.homeManager.communication =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        vesktop
      ];
    };
}
