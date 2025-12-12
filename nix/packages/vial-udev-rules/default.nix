{
  lib,
  stdenvNoCC,
  udevCheckHook,
  writeTextFile,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vial-udev-rules";
  version = "2025-12-12";

  nativeBuildInputs = [udevCheckHook];

  src = writeTextFile {
    name = "59-viia.rules";
    text = ''
      # Keychron Q5
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0151", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };

  dontConfigure = true;
  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/lib/udev/rules.d/59-viia.rules
    runHook postInstall
  '';

  meta = with lib; {
    description = "Vial udev rule";
    license = licenses.mit;
    platforms = platforms.linux;
  };
})
