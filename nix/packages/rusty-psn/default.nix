{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  pkg-config,
  cmake,
  fontconfig,
  glib,
  gtk3,
  freetype,
  openssl,
  xorg,
  libGL,
  wayland,
  libxkbcommon,
  withGui ? true, # build gui version
}:
rustPlatform.buildRustPackage rec {
  pname = "rusty-psn";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "RainbowCookie32";
    repo = "rusty-psn";
    rev = "v${version}";
    sha256 = "sha256-o6utGY8tPI90ba9FyOzhkJ2W1RGOyCLU7TEtHouMiSk=";
  };

  # cargoPatches = [ ./fix-cargo-lock.patch ];

  cargoHash = "sha256-lzBZaS46SMXlmoBfDyBtEuNfjS8VWGXYlC6SugKLB10=";

  # Tests require network access
  doCheck = false;

  nativeBuildInputs =
    [
      pkg-config
    ]
    ++ lib.optionals withGui [
      copyDesktopItems
      cmake
    ];

  buildInputs =
    [
      openssl
    ]
    ++ lib.optionals withGui [
      glib
      gtk3
      freetype
      openssl

      # GUI libs
      libxkbcommon
      libGL
      fontconfig

      # wayland libraries
      wayland

      # x11 libraries
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libX11

      # xorg.libxcb
    ];

  buildNoDefaultFeatures = true;
  buildFeatures = [
    (
      if withGui
      then "egui"
      else "cli"
    )
  ];

  postFixup =
    ''
      patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" $out/bin/rusty-psn
    ''
    + lib.optionalString withGui ''
      mv $out/bin/rusty-psn $out/bin/rusty-psn-gui
    '';

  desktopItem = lib.optionalString withGui (makeDesktopItem {
    name = "rusty-psn";
    desktopName = "rusty-psn";
    exec = "rusty-psn-gui";
    comment = "A simple tool to grab updates for PS3 games, directly from Sony's servers using their updates API.";
    categories = [
      "Network"
    ];
    keywords = [
      "psn"
      "ps3"
      "sony"
      "playstation"
      "update"
    ];
  });
  desktopItems = lib.optionals withGui [desktopItem];

  meta = with lib; {
    description = "Simple tool to grab updates for PS3 games, directly from Sony's servers using their updates API";
    homepage = "https://github.com/RainbowCookie32/rusty-psn/";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    maintainers = with maintainers; [AngryAnt];
    mainProgram = "rusty-psn";
  };
}
