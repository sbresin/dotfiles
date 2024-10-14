{
  stdenv,
  cmake,
  fetchzip,
  pkg-config,
  alsa-lib,
  curl,
  ffmpeg,
  freeimage,
  freetype,
  harfbuzz,
  icu,
  libgit2,
  poppler,
  pugixml,
  SDL2,
  ...
}: let
  pname = "es-de";
  version = "3.1.0";
in
  stdenv.mkDerivation {
    inherit pname version;
    src = fetchzip {
      url = "https://gitlab.com/es-de/emulationstation-de/-/archive/v${version}/emulationstation-de-v${version}.tar.gz";
      hash = "sha256-v9nOY9T5VOVLBUKoDXqwYa1iYvW42iGA+3kpPUOmHkg=";
    };

    nativeBuildInputs = [
      cmake
      pkg-config
    ];

    buildInputs = [
      alsa-lib
      curl
      ffmpeg
      freeimage
      freetype
      harfbuzz
      icu
      libgit2
      poppler
      pugixml
      SDL2
    ];

    installPhase = ''
      install -D ../${pname} $out/bin/${pname}
      install -Dm755 ../es-app/assets/org.es_de.frontend.desktop $out/share/applications/org.es_de.frontend.desktop
      install -Dm644 ../es-app/assets/org.es_de.frontend.svg $out/share/icons/hicolor/scalable/apps/org.es_de.frontend.svg
      cp -r ../resources/ $out/bin/resources/
    '';
  }
