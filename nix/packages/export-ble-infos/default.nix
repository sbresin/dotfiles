{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  chntpw,
}:
stdenvNoCC.mkDerivation {
  pname = "export-ble-infos";
  version = "0.0.1-f390aab";

  src = lib.snowfall.fs.get-file "nix/packages/export-ble-infos/src";

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;

  nativeBuildInputs = [makeWrapper];
  buildInputs = [python3 chntpw];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm 555 $src/export-ble-infos.py $out/bin/export-ble-infos

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/export-ble-infos" --prefix PATH : "${lib.makeBinPath [chntpw]}"
  '';

  meta = with lib; {
    description = "Export your Windows Bluetooth LE keys into Linux!";
    mainProgram = "export-ble-infos";
    homepage = "https://gist.github.com/Mygod/f390aabf53cf1406fc71166a47236ebf";
    license = licenses.asl20;
    # maintainers = [maintainers.greg];
  };
}
