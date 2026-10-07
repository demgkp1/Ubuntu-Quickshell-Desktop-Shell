{
  description = "Ubuntu Quickshell Desktop Shell development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          quickshell.packages.${system}.default
          pkgs.qt6.qtdeclarative
          pkgs.qt6.qt5compat
          pkgs.qt6.qtlottie
          pkgs.pkg-config
          pkgs.matugen
          pkgs.jq
        ];

        shellHook = ''
          export QML2_IMPORT_PATH="$PWD/imports:${pkgs.qt6.qtlottie}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
          echo "=================================================="
          echo " Quickshell Desktop Shell Nix Development Shell"
          echo " Quickshell: $(quickshell --version 2>/dev/null || echo 'ready')"
          echo "=================================================="
        '';
      };
    };
}
