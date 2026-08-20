{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    supertux-milestone1.url = "github:SuperTux-Origins/supertux-milestone1";
    # SuperTux Origins mainline (WASM + Android APK flake outputs).
    supertux-origins.url = "github:SuperTux-Origins/supertux";
  };

  outputs = { self, nixpkgs, supertux-milestone1, supertux-origins }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      supertux-milestone1-wasm = supertux-milestone1.packages.${system}.supertux-milestone1-wasm;
      supertux-milestone1-android = supertux-milestone1.packages.${system}.supertux-milestone1-android;

      supertux-origins-wasm = supertux-origins.packages.${system}.supertux-origins-wasm;
      supertux-origins-android = supertux-origins.packages.${system}.supertux-origins-android;

      site = pkgs.runCommand "site" { } ''
        mkdir -p $out
        cp -v ${./index.html} $out/index.html

        # Milestone 1
        cp -rv ${supertux-milestone1-wasm} $out/milestone1/
        chmod -R u+w $out/milestone1
        SUPERTUX_MILESTONE1_APK=$(basename ${supertux-milestone1-android}/*.apk)
        echo "Milestone1 APK: $SUPERTUX_MILESTONE1_APK"
        cp -v "${supertux-milestone1-android}/$SUPERTUX_MILESTONE1_APK" $out/milestone1/

        # Origins — same pattern under origins/
        cp -rv ${supertux-origins-wasm} $out/origins/
        chmod -R u+w $out/origins
        if [ ! -f $out/origins/supertux-origins.html ]; then
          entry=$(find $out/origins -maxdepth 2 -name '*.html' | head -1 || true)
          if [ -n "$entry" ]; then
            cp -v "$entry" $out/origins/supertux-origins.html
          fi
        fi
        SUPERTUX_ORIGINS_APK=$(basename ${supertux-origins-android}/*.apk)
        echo "Origins APK: $SUPERTUX_ORIGINS_APK"
        cp -v "${supertux-origins-android}/$SUPERTUX_ORIGINS_APK" $out/origins/

        substituteInPlace $out/index.html \
          --subst-var-by SUPERTUX_MILESTONE1_APK "$SUPERTUX_MILESTONE1_APK" \
          --subst-var-by SUPERTUX_ORIGINS_APK "$SUPERTUX_ORIGINS_APK"
      '';

      serveApp = {
        type = "app";
        program = toString (pkgs.writeShellScript "serve-supertux-origins-site" ''
          set -euo pipefail
          export PKG="${site}"
          export SUPERTUX_ORIGINS_PORT="''${SUPERTUX_ORIGINS_PORT:-8765}"
          exec ${./scripts/serve.sh}
        '');
      };
    in
    {
      packages.${system}.default = site;

      # Local preview: build the site, serve over HTTP, open a browser.
      #   nix run .
      #   nix run .#serve
      #   SUPERTUX_ORIGINS_PORT=9000 nix run .#serve
      apps.${system} = {
        default = serveApp;
        serve = serveApp;
      };
    };
}
