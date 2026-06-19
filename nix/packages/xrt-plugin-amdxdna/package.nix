{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  git,
  python3,
  abseil-cpp,
  boost,
  libdrm,
  libuuid,
  ncurses,
  openssl,
  protobuf,
  rapidjson,
  opencl-clhpp,
  opencl-headers,
  ocl-icd,
  jq,
  linuxHeaders,
  pkg-config,
  pybind11 ? python3.pkgs.pybind11,
}:
let
  version = "2.21.75";
in
stdenv.mkDerivation {
  pname = "xrt-plugin-amdxdna";
  inherit version;

  src = fetchFromGitHub {
    owner = "amd";
    repo = "xdna-driver";
    tag = version;
    hash = "sha256-bBiI42bwap6O59MQdIylX7uz+fLUF75RTyNWTJfAFds=";
    fetchSubmodules = true;
  };

  postPatch = ''
    # Remove CPACK packaging cmake
    sed -i '/pkg\.cmake/d' CMake/native.cmake
    # Remove kernel module build
    sed -i '/driver/d' src/CMakeLists.txt
    # Disable -Werror
    find . -name "*.cmake" -exec sed -i 's/-Werror//' {} \;
    # Fix /etc/os-release (nix sandbox)
    find . -name "nativeLnx.cmake" -exec sed -i \
      -e 's|/etc/os-release|/dev/null|g' \
      -e 's|/etc/redhat-release|/dev/null|g' {} \;
    # Provide a stub sys/sdt.h
    mkdir -p sdt-stub/sys
    cp ${../xrt/sdt-stub.h} sdt-stub/sys/sdt.h
  '';

  nativeBuildInputs = [
    cmake
    ninja
    git
    pkg-config
    python3
    pybind11
  ];

  buildInputs = [
    abseil-cpp
    boost
    libdrm
    libuuid
    ncurses
    openssl
    protobuf
    rapidjson
    opencl-clhpp
    opencl-headers
    ocl-icd
    jq
    linuxHeaders
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DXRT_ENABLE_WERROR=OFF"
    "-DXRT_PLUGIN_VERSION_STRING=${version}"
  ];

  preConfigure = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -isystem $PWD/sdt-stub"
  '';

  hardeningDisable = [ "format" ];

  installPhase = ''
    runHook preInstall
    DESTDIR=$out cmake --install . --prefix /
    # Flatten double-prefix
    if [ -d "$out/$out" ]; then
      cp -a "$out/$out"/* "$out/"
      rm -rf "$out/nix"
    fi
    rm -rf "$out/bins"
    runHook postInstall
  '';

  meta = with lib; {
    description = "AMD XDNA driver plugin for XRT";
    homepage = "https://github.com/amd/xdna-driver";
    license = with licenses; [ asl20 unfree ];
    platforms = [ "x86_64-linux" ];
  };
}
