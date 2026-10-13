{
  description = "Cratedig development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      python = pkgs.python313;

      pythonEnv = python.withPackages (
        ps: with ps; [
          # Core
          textual
          numpy
          soundfile
          mutagen
          tomlkit
          platformdirs

          # GUI
          pyside6
          send2trash

          # Analysis
          librosa
          scipy

          # Download
          yt-dlp
          requests

          # Metadata
          musicbrainzngs

          # Conversion
          pyaaf2
        ]
      );
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pythonEnv
          pkgs.ffmpeg
        ];

        shellHook = ''
          echo "Cratedig dev shell"
          echo "Python: $(python --version)"
          echo "ffmpeg: $(ffmpeg -version | head -1)"
        '';
      };
    };
}
