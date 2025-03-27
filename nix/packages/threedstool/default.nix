{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  curl,
  libiconv,
  openssl,
}:
stdenv.mkDerivation {
  pname = "threedstool";
  version = "1.2.7";

  src = fetchFromGitHub {
    owner = "dnasdw";
    repo = "3dstool";
    rev = "9c4336bca8898f3860b41241b8a7d9d4a6772e79";
    sha256 = "sha256-5gKdLxIwi6vqP5VOUHXPaTM1MC5HTMOg+UKo75hQ1AQ=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    curl
    libiconv
    openssl
  ];

  cmakeFlags = [
    (lib.cmakeBool "USE_DEP" false)
  ];

  installPhase = "
    mkdir $out/bin -p
    ls -la CMakeFiles/
    cp /build/source/bin/Release/3dstool${stdenv.hostPlatform.extensions.executable} $out/bin/
  ";

  meta = with lib; {
    license = licenses.mit;
    description = "An all-in-one tool for extracting/creating 3ds roms.";
    platforms = platforms.linux;
    mainProgram = "3dstool";
  };
}
