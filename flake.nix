{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    supertux-milestone1.url = "github:SuperTux-Origins/supertux-milestone1";
  };

  outputs = { self, nixpkgs, supertux-milestone1 }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      supertux-milestone1-wasm = supertux-milestone1.packages.${system}.supertux-milestone1-wasm;
      supertux-milestone1-android = supertux-milestone1.packages.${system}.supertux-milestone1-android;

      site = pkgs.runCommand "site" { } ''
        mkdir -p $out
        cp -v ${./index.html} $out/index.html
        cp -rv ${supertux-milestone1-wasm} $out/milestone1/
        chmod -R u+w $out/milestone1
        ls -hl ${supertux-milestone1-android}
        SUPERTUX_MILESTONE1_APK=$(basename ${supertux-milestone1-android}/*.apk)
        echo "APK:" $SUPERTUX_MILESTONE1_APK
        cp -v "${supertux-milestone1-android}/$SUPERTUX_MILESTONE1_APK" $out/milestone1/
        substituteInPlace $out/index.html \
          --subst-var-by SUPERTUX_MILESTONE1_APK "$SUPERTUX_MILESTONE1_APK" \
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
      # Mirrors `nix run .#supertux-milestone1-wasm` from the game flake.
      #   nix run .
      #   nix run .#serve
      #   SUPERTUX_ORIGINS_PORT=9000 nix run .#serve
      apps.${system} = {
        default = serveApp;
        serve = serveApp;
      };
    };
}
