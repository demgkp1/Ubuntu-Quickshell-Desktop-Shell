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
      qt = pkgs.qt6Packages;
      m3shapes = pkgs.stdenv.mkDerivation {
        pname = "qt6-m3shapes";
        version = "2026-11-16-8a6fe89";
        src = pkgs.fetchFromGitHub {
          owner = "soramanew";
          repo = "m3shapes";
          rev = "8a6fe8961749887d677700b6508e0c9249968b7e";
          sha256 = "1h99dj483awbi43hgamprxzlsya7h9q9qc6p2i0crwh3gm5fvk2n";
        };
        nativeBuildInputs = [ pkgs.cmake pkgs.ninja qt.wrapQtAppsHook ];
        buildInputs = [ qt.qtbase qt.qtdeclarative qt.qtshadertools ];
        dontWrapQtApps = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.cmake pkgs.ninja pkgs.pkg-config qt.wrapQtAppsHook ];
        buildInputs = [
          quickshell.packages.${system}.default m3shapes
          qt.qtbase qt.qtdeclarative qt.qtshadertools qt.qt5compat qt.qtlottie qt.qtsvg
          pkgs.pipewire pkgs.brightnessctl pkgs.libcava pkgs.libxcb pkgs.matugen pkgs.jq pkgs.python3
          pkgs.xorg-server pkgs.openbox pkgs.picom pkgs.imagemagick pkgs.mesa pkgs.libglvnd
          pkgs.ffmpeg-headless pkgs.shellcheck
          pkgs.material-symbols pkgs.lxgw-wenkai-screen pkgs.nerd-fonts.jetbrains-mono
        ];
        dontWrapQtApps = true;
        shellHook = ''
          # nix develop injects an unused output linker directory; escape-free
          # compiler flags break when the checkout path contains spaces.
          export NIX_LDFLAGS="''${NIX_LDFLAGS//"-L$PWD/outputs/out/lib"/}"
          export NIX_LDFLAGS="''${NIX_LDFLAGS//"-rpath $PWD/outputs/out/lib"/}"
          export CLAVIS_QML_DEPS="${m3shapes}/lib/qt6/qml:${qt.qtdeclarative}/lib/qt-6/qml:${qt.qt5compat}/lib/qt-6/qml:${qt.qtlottie}/lib/qt-6/qml"
          export CLAVIS_FONT_DIRS="${pkgs.material-symbols}/share/fonts:${pkgs.lxgw-wenkai-screen}/share/fonts:${pkgs.nerd-fonts.jetbrains-mono}/share/fonts"
          export CLAVIS_QT_VERSION="${qt.qtbase.version}"
          # On non-NixOS, libglvnd's GLX vendor dlopen cannot find the Nix
          # Mesa driver merely from an EGL JSON. Apply these only to Clavis,
          # not to the host session or unrelated programs in the dev shell.
          export CLAVIS_GRAPHICS_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.mesa pkgs.libglvnd ]}"
          export CLAVIS_GL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
          export CLAVIS_EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
        '';
      };
    };
}
