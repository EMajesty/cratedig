{
  description = "Cratedig sample browser and similarity search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pythonEnv = pkgs.python313.withPackages (ps: with ps; [
        textual
        numpy
        soundfile
        mutagen
        tomlkit
        platformdirs
        pyside6
        send2trash
        librosa
        scipy
        yt-dlp
        requests
        musicbrainzngs
      ]);

      cratedig = pkgs.stdenvNoCC.mkDerivation {
        pname = "cratedig";
        version = "0.6.0";
        src = self;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          runHook preInstall

          mkdir -p \
            $out/share/cratedig \
            $out/share/applications \
            $out/share/icons/hicolor/256x256/apps \
            $out/bin

          cp -r cratedig $out/share/cratedig/
          cp -r packaging $out/share/cratedig/
          cp config.example.toml $out/share/cratedig/ 2>/dev/null || true

          makeWrapper ${pythonEnv}/bin/python $out/bin/cratedig \
            --add-flags "-m cratedig gui" \
            --set CRATEDIG_PACKAGED 1 \
            --prefix PYTHONPATH : "$out/share/cratedig" \
            --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}"

          makeWrapper ${pythonEnv}/bin/python $out/bin/cratedig-tui \
            --add-flags "-m cratedig" \
            --set CRATEDIG_PACKAGED 1 \
            --prefix PYTHONPATH : "$out/share/cratedig" \
            --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}"

          ${pkgs.imagemagick}/bin/magick 'packaging/cratedig.ico[0]' \
            -resize 256x256 \
            $out/share/icons/hicolor/256x256/apps/cratedig.png

          cat > $out/share/applications/cratedig.desktop <<EOF
          [Desktop Entry]
          Type=Application
          Name=Cratedig
          Comment=Browse, analyze, and find similar audio samples
          Exec=cratedig
          Icon=cratedig
          Terminal=false
          Categories=AudioVideo;Audio;Music;
          StartupNotify=true
          EOF

          runHook postInstall
        '';

        meta = {
          description = "Local sample browser, downloader, and similarity search";
          mainProgram = "cratedig";
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      packages.${system} = {
        default = cratedig;
        cratedig = cratedig;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${cratedig}/bin/cratedig";
        };
        tui = {
          type = "app";
          program = "${cratedig}/bin/cratedig-tui";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pythonEnv
          pkgs.ffmpeg
        ];

        shellHook = ''
          echo "Cratedig dev shell"
          echo "Python: $(python --version)"
          echo "Run GUI: python -m cratedig gui"
        '';
      };
    };
}
