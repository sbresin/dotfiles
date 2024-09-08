{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-emoji-linux";
  version = "17.4";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
    hash = "sha256-SG3JQLybhY/fMX+XqmB/BKhQSBB0N1VRqa+H6laVUPE=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm 444 $src $out/share/fonts/apple-emoji-linux/AppleColorEmoji.ttf
    runHook postInstall
  '';

  meta = {
    description = "Brings Apple's vibrant emojis to your Linux experience";
    homepage = "https://github.com/samuelngs/apple-emoji-linux";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    maintainers = [];
  };
}
