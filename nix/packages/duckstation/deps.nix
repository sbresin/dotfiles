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
}: let
  shaderc = "1c0d3d18819aa75ec74f1fbd9ff0461e1b69a4d6";
  cpuinfo = "7524ad504fdcfcf75a18a133da6abd75c5d48053";
  discord-rpc = "144f3a3f1209994d8d9e8a87964a989cb9911c1e";
  libbacktrace = "86885d14049fab06ef8a33aac51664230ca09200";
  lunasvg = "9af1ac7b90658a279b372add52d6f77a4ebb482c";
  sdl2 = "2.30.8";
  soundtouch = "463ade388f3a51da078dc9ed062bf28e4ba29da7";
  spirv_cross = "vulkan-sdk-1.3.290.0";

  shaderc_src = fetchurl {
    url = "https://github.com/stenzek/shaderc/archive/${shaderc}.tar.gz";
    hash = "sha256-OCbYb4oTVkvhwEesEFBBo8XQ3Av4Jv5HzFgv4Xos57E=";
  };
  cpuinfo_src = fetchurl {
    url = "https://github.com/stenzek/cpuinfo/archive/${cpuinfo}.tar.gz";
    hash = "sha256-4TUSGNJw20nD3dy6BPshU7CXMeo/poMOQj9ZUvRFhb4=";
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
  sdl2_src = fetchurl {
    url = "https://github.com/libsdl-org/SDL/releases/download/release-${sdl2}/SDL2-${sdl2}.tar.gz";
    hash = "sha256-OAwpXqdrm9ctkAdXk5cci8sjK6CmmpsU2kro9gM1AFg=";
  };
  soundtouch_src = fetchurl {
    url = "https://github.com/stenzek/soundtouch/archive/${soundtouch}.tar.gz";
    hash = "sha256-/kXCr5n2EC0nBCd9OSwcg7VRgKcL/Rf7iIzISlS3BXM=";
  };
  spirv_src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
    rev = spirv_cross;
    hash = "sha256-3E+a1XYpfANYCLC3AUxeUyi3aLe0dT1FUpq8Wufsw0E=";
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

    postPatch = ''
      mkdir -p deps-build

      # symlink them all to location expected by ./scripts/deps/build-dependencies-linux.sh
      ln -s "${cpuinfo_src}" "deps-build/cpuinfo-${cpuinfo}.tar.gz"
      ln -s "${libbacktrace_src}" "deps-build/${libbacktrace}.tar.gz"
      ln -s "${sdl2_src}" "deps-build/SDL2-${sdl2}.tar.gz"
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
        -system-libpng -system-libwebp -system-libzip -system-zstd -system-qt \
        -skip-download -skip-cleanup \
        "$out"

      runHook postBuild
    '';

    dontInstall = true;
  }
