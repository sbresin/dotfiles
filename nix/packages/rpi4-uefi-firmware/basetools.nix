{
  pkgs,
  stdenv,
  python3,
  libuuid,
  ...
}: let
  sources = pkgs.callPackage ./sources.nix {};
in
  stdenv.mkDerivation {
    name = "edk2";

    src = sources.edk2;

    nativeBuildInputs = [python3 libuuid];
    buildInputs = [libuuid];

    sourceRoot = ".";
    postUnpack = ''
      chmod -R +w edk2*
    '';

    buildPhase = ''
      runHook preBuild

      export PYTHON_COMMAND="${python3}/bin/python3"
      export WORKSPACE="$PWD"
      export PACKAGES_PATH=$PWD/edk2:$PWD/edk2-platforms:$PWD/edk2-non-osi

      # set -x

      . edk2/edksetup.sh BaseTools

      make -C edk2/BaseTools

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R edk2/* $out/
      runHook postInstall
    '';

    # dontFixup = true;
  }
