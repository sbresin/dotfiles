{
  lib,
  stdenv,
  fetchFromGitHub,
  qt5,
}:
stdenv.mkDerivation {
  pname = "ddctoolbox";
  version = "2.0.1-unstable-2026-04-11";

  src = fetchFromGitHub {
    owner = "ThePBone";
    repo = "DDCToolbox";
    rev = "c67dd278e8b2fe0c9e4d5bc2ccdd54c0cce16728";
    hash = "sha256-zrzQY1A1yaDfIvXEFvJNExcOcygilG6Sa1U3YipYex4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    qt5.qmake
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    qt5.qtbase
  ];

  # Upstream code has implicit function declarations that GCC 14+ treats as errors
  env.NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";

  qmakeFlags = [ "CONFIG+=no_tests" ];

  postPatch = ''
    substituteInPlace snap/gui/ddctoolbox.desktop \
      --replace-fail 'Icon=''${SNAP}/meta/gui/ddctoolbox.svg' 'Icon=ddctoolbox' \
      --replace-fail 'Type=Application ' 'Type=Application'
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 src/DDCToolbox $out/bin/ddctoolbox
    install -Dm644 snap/gui/ddctoolbox.desktop $out/share/applications/ddctoolbox.desktop
    install -Dm644 snap/gui/ddctoolbox.svg $out/share/icons/hicolor/scalable/apps/ddctoolbox.svg
    runHook postInstall
  '';

  meta = {
    description = "Create and edit DDC headset correction files";
    homepage = "https://github.com/ThePBone/DDCToolbox";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ddctoolbox";
  };
}
