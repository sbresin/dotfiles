{
  callPackage,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  perl,
  python3,
  wayland,
  libxkbcommon,
  libGL,
  libdrm,
  mesa,
  xorg,
}: let
  shaderc = "fc65b19d2098cf81e55b4edc10adad2ad8268361";
  cpuinfo = "3ebbfd45645650c4940bf0f3b4d25ab913466bb0";
  discord-rpc = "144f3a3f1209994d8d9e8a87964a989cb9911c1e";
  libbacktrace = "86885d14049fab06ef8a33aac51664230ca09200";
  lunasvg = "9af1ac7b90658a279b372add52d6f77a4ebb482c";
  sdl3 = "3.2.4";
  soundtouch = "463ade388f3a51da078dc9ed062bf28e4ba29da7";
  spirv_cross = "vulkan-sdk-1.4.304.0";

  shaderc_src = fetchurl {
    url = "https://github.com/stenzek/shaderc/archive/${shaderc}.tar.gz";
    hash = "sha256-0e+RLCfgYwfysqW2OGBw0Lj64rtYUfUIQd97c9z1q98=";
  };
  cpuinfo_src = fetchurl {
    url = "https://github.com/stenzek/cpuinfo/archive/${cpuinfo}.tar.gz";
    hash = "sha256-tggyBxkZIg0v5pIVH7Qg+p6kiapMei6w4ByDDL5GmFg=";
  };
  discord-rpc_src = fetchurl {
    url = "https://github.com/stenzek/discord-rpc/archive/${discord-rpc}.tar.gz";
    hash = "sha256-PupczOZnDBJigvG6TTLBnUhttJoaXL+41vSHdHhNMQw=";
  };
  libbacktrace_src = fetchurl {
    url = "https://github.com/ianlancetaylor/libbacktrace/archive/${libbacktrace}.tar.gz";
    hash = "sha256-uviuvSIAK3YtgDug4eOJtrRBUVkzTp00u6GpOPbejOY=";
  };
  lunasvg_src = fetchurl {
    url = "https://github.com/stenzek/lunasvg/archive/${lunasvg}.tar.gz";
    hash = "sha256-OZiwJLDUQmFKnuJw524Bi7N6F7jGlBISFxcxEjy7ysc=";
  };
  sdl3_src = fetchurl {
    url = "https://github.com/libsdl-org/SDL/releases/download/release-${sdl3}/SDL3-${sdl3}.tar.gz";
    hash = "sha256-KTgygxcwHfvjAXbXnCUXM6pefsXENsgAuZ7U2nrcsPA=";
  };
  soundtouch_src = fetchurl {
    url = "https://github.com/stenzek/soundtouch/archive/${soundtouch}.tar.gz";
    hash = "sha256-/kXCr5n2EC0nBCd9OSwcg7VRgKcL/Rf7iIzISlS3BXM=";
  };
  spirv_src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
    rev = spirv_cross;
    hash = "sha256-KIWptAhjnWw6nqCfTOnNs0XytFHqBO9On2N1JUcGVxA=";
    leaveDotGit = true;
  };

  sources = callPackage ./sources.nix {};
in
  stdenv.mkDerivation {
    inherit (sources.duckstation) src version;
    pname = "duckstation-deps";

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      perl
      python3
    ];

    buildInputs = [
      wayland
      libxkbcommon
      libGL
      libdrm
      mesa
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcursor
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
    ];

    postPatch = ''
      mkdir -p deps-build

      # symlink them all to location expected by ./scripts/deps/build-dependencies-linux.sh
      ln -s "${cpuinfo_src}" "deps-build/cpuinfo-${cpuinfo}.tar.gz"
      ln -s "${libbacktrace_src}" "deps-build/libbacktrace-${libbacktrace}.tar.gz"
      ln -s "${sdl3_src}" "deps-build/SDL3-${sdl3}.tar.gz"
      ln -s "${discord-rpc_src}" "deps-build/discord-rpc-${discord-rpc}.tar.gz"
      ln -s "${lunasvg_src}" "deps-build/lunasvg-${lunasvg}.tar.gz"
      ln -s "${shaderc_src}" "deps-build/shaderc-${shaderc}.tar.gz"
      ln -s "${soundtouch_src}" "deps-build/soundtouch-${soundtouch}.tar.gz"

      # cp SPIRV-Cross cloned git source
      cp -r "${spirv_src}" "deps-build/SPIRV-Cross"
      chmod -R 777 deps-build/SPIRV-Cross

      patchShebangs --build ./scripts/deps/build-dependencies-linux.sh
    '';

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      ./scripts/deps/build-dependencies-linux.sh -system-freetype -system-harfbuzz -system-libjpeg \
        -system-libpng -system-libwebp -system-libzip -system-zlib -system-zstd -system-qt \
        -skip-download -skip-cleanup \
        "$out"

      runHook postBuild
    '';

    dontInstall = true;
  }
