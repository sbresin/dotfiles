{
  lib,
  fetchzip,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "dank-mono";
  version = "0.1";

  src = fetchzip {
    url = "file://${lib.snowfall.fs.get-file "nix/packages/dank-mono/Dank_Mono_15_Oct_2020.encrypted.zip"}";
    hash = "sha256-0OTANoEoZTqDFiQLHVw+ytStWMOiB/Z/V2M9ZWTQSCE=";
    stripRoot = false;
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = false;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/fonts/opentype/ $src/DankMono/OpenType-PS/*.otf
    runHook postInstall
  '';

  meta = with lib; {
    description = "A typeface designed for coding aesthetes with modern displays in mind";
    homepage = "https://philpl.gumroad.com/l/dank-mono";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
