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
  glibc,
  libdrm,
  ncurses,
  libuuid,
  openssl,
  pkg-config,
  protobuf,
  rapidjson,
  opencl-clhpp,
  opencl-headers,
  ocl-icd,
  xrt-plugin-amdxdna,
  pybind11 ? python3.pkgs.pybind11,
}:
let
  version = "2.21.75";
in
stdenv.mkDerivation {
  pname = "xrt";
  inherit version;

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "XRT";
    tag = version;
    hash = "sha256-sujiSRZuIelhvUew7yeCfApAmp/Pf2+F38KO9cxI2HE=";
    fetchSubmodules = true;
  };

  patches = [
    ./install-to-bin.patch
  ];

  postPatch = ''
    # /etc/os-release doesn't exist in the nix sandbox
    substituteInPlace src/CMake/nativeLnx.cmake \
      --replace-fail '/etc/os-release' /dev/null \
      --replace-fail '/etc/redhat-release' /dev/null

    # Provide a stub sys/sdt.h (systemtap not in nixpkgs)
    mkdir -p sdt-stub/sys
    cp ${./sdt-stub.h} sdt-stub/sys/sdt.h

    # aiebu: strip upstream -static flags (we re-add them selectively below)
    find src/runtime_src/core/common/aiebu -name CMakeLists.txt \
      -exec sed -i 's/-static//g' {} \;

    # aiebu: remove dynamic-dependency checks (expect fully-static binaries)
    find src/runtime_src/core/common/aiebu -name CMakeLists.txt \
      -exec sed -i '/_check_dynamic_deps/,/)/d' {} \;

    # aiebu: remove spec doc target (tries to wget at install time)
    find src/runtime_src/core/common/aiebu -name CMakeLists.txt \
      -exec sed -i '/add_subdirectory.*specification/d' {} \;

    # Redirect /etc/OpenCL install into $out
    sed -i 's|/etc/OpenCL|''${CMAKE_INSTALL_PREFIX}/etc/OpenCL|g' src/CMake/icd.cmake

    # IFUNC workaround: the nix sandbox's dynamic linker conflicts with
    # build-time generator executables (preemption, copy, aiebu-asm).
    # Static-link them with explicit glibc.static so they bypass ld.so.
    sed -i '/target_link_libraries(''${AIEBU_PREEMPTION_EXE} xaiengine)/a\
target_link_options(''${AIEBU_PREEMPTION_EXE} PRIVATE -static "-L${glibc.static}/lib")' \
      src/runtime_src/core/common/aiebu/lib/src/CMakeLists.txt
    sed -i '/target_link_libraries(''${AIEBU_COPY_EXE} PRIVATE xaiengine aiebu_static)/a\
target_link_options(''${AIEBU_COPY_EXE} PRIVATE -static "-L${glibc.static}/lib")' \
      src/runtime_src/core/common/aiebu/lib/src/CMakeLists.txt
    find src/runtime_src/core/common/aiebu -name CMakeLists.txt \
      -exec sed -i '/target_link_libraries(aiebu-asm PRIVATE aiebu_static)/a\
target_link_options(aiebu-asm PRIVATE -static "-L${glibc.static}/lib")' {} \;
  '';

  nativeBuildInputs = [
    cmake
    ninja
    git
    pkg-config
    python3
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
    pybind11
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DXRT_ENABLE_WERROR=OFF"
    "-DXRT_BASE=1"
    "-DXRT_ALVEO=0"
    "-DXRT_BUILD_NUMBER=${lib.last (lib.splitString "." version)}"
  ];

  preConfigure = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -isystem $PWD/sdt-stub"
  '';

  hardeningDisable = [ "format" ];

  postInstall = ''
    # Flatten double-prefix ($out/$out -> $out)
    if [ -d "$out/$out" ]; then
      cp -a "$out/$out"/* "$out/"
      rm -rf "$out/nix"
    fi
    rm -f $out/include/CL/cl_ext.h

    # Keep the XDNA driver plugin beside the XRT core libs so
    # upstream driver discovery works without extra path hacks.
    ln -sf "${xrt-plugin-amdxdna}/lib/libxrt_driver_xdna.so.${version}" "$out/lib/libxrt_driver_xdna.so.${version}"
    ln -sf "${xrt-plugin-amdxdna}/lib/libxrt_driver_xdna.so.2" "$out/lib/libxrt_driver_xdna.so.2"
  '';

  preFixup = ''
    # Fix pkgconfig double-prefix paths
    for pc in $out/lib/pkgconfig/*.pc; do
      [ -f "$pc" ] || continue
      sed -i "s|\''${prefix}/\?$out|$out|g" "$pc"
      sed -i "s|//$out|$out|g" "$pc"
    done
  '';

  meta = with lib; {
    description = "Xilinx Runtime for AIE and FPGA based platforms";
    homepage = "https://xilinx.github.io/XRT/";
    license = with licenses; [ asl20 gpl2Only ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "xrt-smi";
  };
}
