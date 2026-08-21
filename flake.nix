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
      supertux-milestone1-win32-x86 = supertux-milestone1.packages.${system}.supertux-milestone1-win32-x86-zip;
      supertux-milestone1-win32-x64 = supertux-milestone1.packages.${system}.supertux-milestone1-win32-x64-zip;
      supertux-milestone1-r36s = supertux-milestone1.packages.${system}.supertux-milestone1-r36s-portmaster-zip;

      supertux-origins-wasm = supertux-origins.packages.${system}.supertux-origins-wasm;
      supertux-origins-android = supertux-origins.packages.${system}.supertux-origins-android;
      supertux-origins-win32 = supertux-origins.packages.${system}.supertux-origins-win32-zip;
      supertux-origins-r36s = supertux-origins.packages.${system}.supertux-origins-r36s-portmaster-zip;

      site = pkgs.runCommand "site" { } ''
        mkdir -p $out
        cp -v ${./index.html} $out/index.html

        # Milestone 1
        cp -rv ${supertux-milestone1-wasm} $out/milestone1/
        chmod -R u+w $out/milestone1

        SUPERTUX_MILESTONE1_APK=$(basename ${supertux-milestone1-android}/*.apk)
        echo "Milestone1 APK: $SUPERTUX_MILESTONE1_APK"
        cp -v "${supertux-milestone1-android}/$SUPERTUX_MILESTONE1_APK" $out/milestone1/

        SUPERTUX_MILESTONE1_WIN32_X86=$(basename ${supertux-milestone1-win32-x86}/*.zip)
        echo "Milestone1 Win32 (32-bit): $SUPERTUX_MILESTONE1_WIN32_X86"
        cp -v "${supertux-milestone1-win32-x86}/$SUPERTUX_MILESTONE1_WIN32_X86" $out/milestone1/

        SUPERTUX_MILESTONE1_WIN32_X64=$(basename ${supertux-milestone1-win32-x64}/*.zip)
        echo "Milestone1 Win32 (64-bit): $SUPERTUX_MILESTONE1_WIN32_X64"
        cp -v "${supertux-milestone1-win32-x64}/$SUPERTUX_MILESTONE1_WIN32_X64" $out/milestone1/

        SUPERTUX_MILESTONE1_R36S=$(basename ${supertux-milestone1-r36s}/*.zip)
        echo "Milestone1 R36S: $SUPERTUX_MILESTONE1_R36S"
        cp -v "${supertux-milestone1-r36s}/$SUPERTUX_MILESTONE1_R36S" $out/milestone1/

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

        SUPERTUX_ORIGINS_WIN32=$(basename ${supertux-origins-win32}/*.zip)
        echo "Origins Win32: $SUPERTUX_ORIGINS_WIN32"
        cp -v "${supertux-origins-win32}/$SUPERTUX_ORIGINS_WIN32" $out/origins/

        SUPERTUX_ORIGINS_R36S=$(basename ${supertux-origins-r36s}/*.zip)
        echo "Origins R36s: $SUPERTUX_ORIGINS_R36S"
        cp -v "${supertux-origins-r36s}/$SUPERTUX_ORIGINS_R36S" $out/origins/

        # --subst-var-by SUPERTUX_MILESTONE1_WIN32 "$SUPERTUX_MILESTONE1_WIN32"
        substituteInPlace $out/index.html \
          --subst-var-by SUPERTUX_MILESTONE1_APK "$SUPERTUX_MILESTONE1_APK" \
          --subst-var-by SUPERTUX_MILESTONE1_WIN32_X86 "$SUPERTUX_MILESTONE1_WIN32_X86" \
          --subst-var-by SUPERTUX_MILESTONE1_WIN32_X64 "$SUPERTUX_MILESTONE1_WIN32_X64" \
          --subst-var-by SUPERTUX_MILESTONE1_R36S "$SUPERTUX_MILESTONE1_R36S" \
          --subst-var-by SUPERTUX_ORIGINS_APK "$SUPERTUX_ORIGINS_APK" \
          --subst-var-by SUPERTUX_ORIGINS_WIN32 "$SUPERTUX_ORIGINS_WIN32" \
          --subst-var-by SUPERTUX_ORIGINS_R36S "$SUPERTUX_ORIGINS_R36S"
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
