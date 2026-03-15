{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-emoji-linux";
  version = "macos-26-20260219-2aa12422";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${version}/AppleColorEmoji-Linux.ttf";
    hash = "sha256-U1oEOvBHBtJEcQWeZHRb/IDWYXraLuo0NdxWINwPUxg=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm 444 $src $out/share/fonts/apple-emoji-linux/AppleColorEmoji.ttf
    runHook postInstall
  '';

  meta = {
    description = "Brings Apple's vibrant emojis to your Linux experience";
    homepage = "https://github.com/samuelngs/apple-emoji-ttf";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
}
