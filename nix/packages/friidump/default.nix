{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation {
  pname = "friidump";
  version = "gertoe-2021-01-10";

  src = fetchFromGitHub {
    owner = "gertoe";
    repo = "friidump";
    rev = "bd9f48e274827ca9275561d6ecd351e25942ab84";
    sha256 = "sha256-1nXkYpqtmYLFtqDdnGjzHUHYG+cKesz+ph0rfbOtA8A=";
  };

  patches = [
    ./fix_disctype.patch
  ];

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-DBUILD_STATIC_BINARY=ON"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp src/friidump $out/bin/
  '';

  meta = with lib; {
    license = licenses.gpl2;
    description = "Dump Nintendo Wii and GameCube discs";
    platforms = platforms.linux;
    mainProgram = "friidump";
  };
}
