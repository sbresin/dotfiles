{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitea,
  xorg,
  libgdiplus,
  ffmpeg,
  openal,
  libsoundio,
  sndio,
  pulseaudio,
  vulkan-loader,
  glew,
  libGL,
  udev,
  SDL2,
  SDL2_mixer,
}:
buildDotnetModule rec {
  pname = "ryujinx";
  version = "1.1.1401"; # Based off of the official github actions builds: https://github.com/Ryujinx/Ryujinx/actions/workflows/release.yml

  # src = fetchFromGitea {
  #   domain = "git.l7y.media";
  #   owner = "mirrors";
  #   repo = "Ryujinx";
  #   rev = "a2c003501371463fd1f98d2e5a7602ae19c21d7c";
  #   hash = "sha256-nzHk42OPH+52hHmVzbpc1NDZAAgwvuasbNA6zuUJXOE=";
  # };
  src = fetchTarball {
    url = "file:///home/sebe/workspace/Ryujinx.tar.gz";
    sha256 = "sha256:0q3l4g0db4g30r6jpybn1a9ryjs1pz242535qigz3k8s8v9zk5dw";
  };

  enableParallelBuilding = false;

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  nugetDeps = ./deps.nix;

  runtimeDeps = [
    xorg.libX11
    libgdiplus
    SDL2_mixer
    openal
    libsoundio
    sndio
    pulseaudio
    vulkan-loader
    ffmpeg
    udev

    # Avalonia UI
    glew

    # Headless executable
    libGL
    SDL2
  ];

  projectFile = "Ryujinx.sln";
  testProjectFile = "src/Ryujinx.Tests/Ryujinx.Tests.csproj";
  doCheck = true;

  dotnetFlags = [
    "/p:ExtraDefineConstants=DISABLE_UPDATER%2CFORCE_EXTERNAL_BASE_DIR"
  ];

  executables = [
    "Ryujinx.Headless.SDL2"
    "Ryujinx"
  ];

  makeWrapperArgs = [
    # Without this Ryujinx fails to start on wayland. See https://github.com/Ryujinx/Ryujinx/issues/2714
    "--set SDL_VIDEODRIVER x11"
  ];

  preInstall = ''
    # workaround for https://github.com/Ryujinx/Ryujinx/issues/2349
    mkdir -p $out/lib/sndio-6
    ln -s ${sndio}/lib/libsndio.so $out/lib/sndio-6/libsndio.so.6
  '';

  preFixup = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps,mime/packages}
    pushd ${src}/distribution/linux

    install -D ./Ryujinx.desktop $out/share/applications/Ryujinx.desktop
    install -D ./Ryujinx.sh $out/bin/Ryujinx.sh
    install -D ./mime/Ryujinx.xml $out/share/mime/packages/Ryujinx.xml
    install -D ../misc/Logo.svg $out/share/icons/hicolor/scalable/apps/Ryujinx.svg

    substituteInPlace $out/share/applications/Ryujinx.desktop \
      --replace "Ryujinx.sh %f" "$out/bin/Ryujinx.sh %f"

    ln -s $out/bin/Ryujinx $out/bin/ryujinx

    popd
  '';

  passthru.updateScript = ./updater.sh;

  meta = with lib; {
    homepage = "https://ryujinx.org/";
    changelog = "https://github.com/Ryujinx/Ryujinx/wiki/Changelog";
    description = "Experimental Nintendo Switch Emulator written in C#";
    longDescription = ''
      Ryujinx is an open-source Nintendo Switch emulator, created by gdkchan,
      written in C#. This emulator aims at providing excellent accuracy and
      performance, a user-friendly interface and consistent builds. It was
      written from scratch and development on the project began in September
      2017.
    '';
    license = licenses.mit;
    maintainers = with maintainers; [jk artemist];
    platforms = ["x86_64-linux" "aarch64-linux"];
    mainProgram = "Ryujinx";
  };
}
