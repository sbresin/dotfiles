{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  git,
  boost,
  curl,
  ffmpeg,
  fftw,
  fftwFloat,
  fftwLongDouble,
  libdrm,
  libuuid,
  readline,
  cargo,
  rustc,
  rustPlatform,
  xrt,
  xrt-plugin-amdxdna,
}:
let
  version = "0.9.45";
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };
in
stdenv.mkDerivation {
  pname = "fastflowlm";
  inherit version;

  src = fetchFromGitHub {
    owner = "FastFlowLM";
    repo = "FastFlowLM";
    tag = "v${version}";
    hash = "sha256-VR2Var+tGPTwbuV1WE4eUqmb9RHnPkB3Z+2oQhGuplg=";
    fetchSubmodules = true;
  };

  sourceRoot = "source/src";

  postUnpack = ''
    # Copy Cargo.lock (missing from upstream) and set up vendored deps
    chmod -R u+w source/third_party/tokenizers-cpp/rust
    cp ${./Cargo.lock} source/third_party/tokenizers-cpp/rust/Cargo.lock
    mkdir -p source/third_party/tokenizers-cpp/rust/.cargo
    vendorDir=$(readlink -f ${cargoDeps})
    cat > source/third_party/tokenizers-cpp/rust/.cargo/config.toml <<EOF
    [source.crates-io]
    replace-with = "vendored-sources"

    [source.vendored-sources]
    directory = "$vendorDir"
    EOF
  '';

  nativeBuildInputs = [
    cmake
    ninja
    git
    cargo
    rustc
  ];

  buildInputs = [
    boost
    curl
    ffmpeg
    fftw
    fftwFloat
    fftwLongDouble
    libdrm
    libuuid
    readline
    xrt
    xrt-plugin-amdxdna
  ];

  postPatch = ''
    # Fix hardcoded XRT path
    find . -name "CMakeLists.txt" -exec sed -i \
      -e 's|/opt/xilinx/xrt|${xrt}|g' {} \;
    find . -name "*.cmake" -exec sed -i \
      -e 's|/opt/xilinx/xrt|${xrt}|g' {} \;
    # Remove the /usr/local/bin symlink creation block (nix handles PATH)
    sed -i '/NOT CMAKE_INSTALL_PREFIX STREQUAL.*usr.local/,/endif()/d' CMakeLists.txt
  '';

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_XCLBIN_PREFIX=${placeholder "out"}/share/flm"
    "-DFLM_VERSION=${version}"
    # Driver version check only applies to Windows
    "-DNPU_VERSION=dummy"
  ];

  hardeningDisable = [ "format" ];

  postInstall = ''
    # Flatten double-prefix if present
    if [ -d "$out/$out" ]; then
      cp -a "$out/$out"/* "$out/"
      rm -rf "$out/nix"
    fi
    # Remove vendored headers and cmake files
    rm -rf $out/include $out/lib/cmake
  '';

  # Precompiled .so libs (e.g. libgemma_npu.so) link against libgomp but
  # ship without an RPATH. Patch them so the GCC runtime is found.
  postFixup = ''
    for so in $out/lib/*.so; do
      [ -f "$so" ] || continue
      patchelf --add-rpath "${stdenv.cc.cc.lib}/lib" "$so"
    done
  '';

  meta = with lib; {
    description = "Run LLMs on AMD Ryzen AI NPUs";
    homepage = "https://www.fastflowlm.com/";
    license = with licenses; [ mit unfree ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "flm";
  };
}
