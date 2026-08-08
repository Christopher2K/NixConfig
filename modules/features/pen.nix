{
  flake.modules.homeManager.pen =
    { pkgs, ... }:
    let
      pname = "pen";
      version = "1.2.4";
      # pen.dev serves an unversioned "latest" URL; bump hash and version
      # (X-AppImage-Version in the extracted pen.desktop) on upstream releases.
      src = pkgs.fetchurl {
        url = "https://www.pen.dev/download/Pen-linux-x86_64.AppImage";
        hash = "sha256-XA4W9/5DcRfGMNZ95EQFE/F7znD33olh6y+EAy2fm+c=";
      };
      appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    {
      home.packages = [
        (pkgs.appimageTools.wrapType2 {
          inherit pname version src;
          extraInstallCommands = ''
            install -m 444 -D ${appimageContents}/pen.desktop $out/share/applications/pen.desktop
            substituteInPlace $out/share/applications/pen.desktop \
              --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=pen %U'
            install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/pen.png \
              $out/share/icons/hicolor/512x512/apps/pen.png
          '';
        })
      ];
    };
}
